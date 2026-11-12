require 'json'
require 'net/http'
require 'uri'

# Starts and follows Xcode Cloud builds through the App Store Connect API, so
# a GitHub Actions job on Linux can hand the archive to Xcode Cloud and still
# own everything around it (notes, Phabricator, failure reporting).
#
# Spaceship does not wrap the ci* endpoints, so this makes plain HTTP calls,
# signing each one with a fresh JWT from the same API key the rest of the
# Fastfile uses. A fresh token per request means a long poll never outlives
# the token's 20 minute lifetime.
module XcodeCloud
  API_ROOT = "https://api.appstoreconnect.apple.com"

  class Error < StandardError; end

  class Client
    def initialize(key_id:, issuer_id:, key:, log: ->(message) { puts(message) })
      @key_id = key_id
      @issuer_id = issuer_id
      @key = key
      @log = log
    end

    # ---- Lookups ----------------------------------------------------------

    def app_id(bundle_id)
      apps = get("/v1/apps", "filter[bundleId]" => bundle_id, "limit" => "1")["data"]
      raise Error, "No App Store Connect app with bundle ID #{bundle_id}" if apps.empty?
      apps.first["id"]
    end

    def product_id(app_id)
      product = get("/v1/apps/#{app_id}/ciProduct")["data"]
      raise Error, "App #{app_id} has no Xcode Cloud product" if product.nil?
      product["id"]
    end

    def workflow_id(product_id, name)
      workflows = paginate("/v1/ciProducts/#{product_id}/workflows", "limit" => "200")
      match = workflows.find { |w| w.dig("attributes", "name") == name }
      if match.nil?
        names = workflows.map { |w| w.dig("attributes", "name") }
        raise Error, "No Xcode Cloud workflow named #{name.inspect}. Workflows: #{names.join(', ')}"
      end
      if match.dig("attributes", "isEnabled") == false
        raise Error, "Xcode Cloud workflow #{name.inspect} is disabled"
      end
      match["id"]
    end

    # The repository has thousands of tags, and gitReferences has no filter,
    # so this pages until it finds the branch rather than reading every page.
    def git_reference_id(workflow_id, canonical_name)
      repository = get("/v1/ciWorkflows/#{workflow_id}/repository")["data"]
      raise Error, "Workflow #{workflow_id} has no repository" if repository.nil?
      paginate("/v1/scmRepositories/#{repository['id']}/gitReferences", "limit" => "200") do |reference|
        return reference["id"] if reference.dig("attributes", "canonicalName") == canonical_name
      end
      raise Error, "Xcode Cloud cannot see #{canonical_name} in repository #{repository['id']}"
    end

    # ---- Build runs -------------------------------------------------------

    def start_build_run(workflow_id:, git_reference_id:)
      body = {
        data: {
          type: "ciBuildRuns",
          attributes: { clean: false },
          relationships: {
            workflow: { data: { type: "ciWorkflows", id: workflow_id } },
            sourceBranchOrTag: { data: { type: "scmGitReferences", id: git_reference_id } },
          },
        },
      }
      post("/v1/ciBuildRuns", body)["data"]
    end

    def build_run(id)
      get("/v1/ciBuildRuns/#{id}")["data"]
    end

    # Returns the finished build run. Raises if it does not succeed or does
    # not finish within timeout seconds.
    def wait_for_build_run(id, timeout:, interval: 60, sleeper: ->(s) { sleep(s) }, clock: -> { Time.now })
      deadline = clock.call + timeout
      last_progress = nil
      loop do
        run = build_run(id)
        attributes = run["attributes"] || {}
        progress = attributes["executionProgress"]
        if progress != last_progress
          @log.call("Xcode Cloud build #{attributes['number']}: #{progress}")
          last_progress = progress
        end

        if progress == "COMPLETE"
          status = attributes["completionStatus"]
          return run if status == "SUCCEEDED"
          raise Error, "Xcode Cloud build #{attributes['number']} finished as #{status}. " \
                       "See the build in App Store Connect > Xcode Cloud for the logs."
        end

        if clock.call >= deadline
          raise Error, "Xcode Cloud build #{attributes['number']} did not finish within #{timeout / 60} minutes (last state #{progress})"
        end
        sleeper.call(interval)
      end
    end

    # The TestFlight build a build run produced: its id, marketing version and
    # build number. The archive is uploaded by the run's TestFlight
    # post-action, so the build can take a few minutes to show up here.
    def produced_build(run_id, timeout: 15 * 60, interval: 30, sleeper: ->(s) { sleep(s) }, clock: -> { Time.now })
      deadline = clock.call + timeout
      loop do
        build = get("/v1/ciBuildRuns/#{run_id}/builds", "limit" => "1")["data"].first
        if build
          version = get("/v1/builds/#{build['id']}/preReleaseVersion")["data"]
          return {
            id: build["id"],
            build_number: build.dig("attributes", "version"),
            version: version&.dig("attributes", "version"),
          }
        end
        if clock.call >= deadline
          raise Error, "Xcode Cloud build run #{run_id} succeeded but no TestFlight build appeared within #{timeout / 60} minutes. " \
                       "Check the workflow still has its TestFlight post-action."
        end
        sleeper.call(interval)
      end
    end

    def wait_for_build_processing(build_id, timeout: 45 * 60, interval: 30, sleeper: ->(s) { sleep(s) }, clock: -> { Time.now })
      deadline = clock.call + timeout
      loop do
        state = get("/v1/builds/#{build_id}")["data"].dig("attributes", "processingState")
        return if state == "VALID"
        if %w[FAILED INVALID].include?(state)
          raise Error, "TestFlight build #{build_id} finished processing as #{state}"
        end
        if clock.call >= deadline
          raise Error, "TestFlight build #{build_id} still #{state} after #{timeout / 60} minutes"
        end
        sleeper.call(interval)
      end
    end

    # Sets the "What to Test" text, creating the localization if the upload
    # did not. TestFlight caps whatsNew at 4000 characters.
    def set_what_to_test(build_id, text, locale: "en-US")
      text = text[0, 4000]
      existing = get("/v1/builds/#{build_id}/betaBuildLocalizations", "limit" => "50")["data"]
        .find { |l| l.dig("attributes", "locale") == locale }
      if existing
        patch("/v1/betaBuildLocalizations/#{existing['id']}", {
          data: { type: "betaBuildLocalizations", id: existing["id"], attributes: { whatsNew: text } },
        })
      else
        post("/v1/betaBuildLocalizations", {
          data: {
            type: "betaBuildLocalizations",
            attributes: { locale: locale, whatsNew: text },
            relationships: { build: { data: { type: "builds", id: build_id } } },
          },
        })
      end
    end

    # ---- HTTP -------------------------------------------------------------

    def get(path, params = {})
      request(Net::HTTP::Get, path, params: params)
    end

    def post(path, body)
      request(Net::HTTP::Post, path, body: body)
    end

    def patch(path, body)
      request(Net::HTTP::Patch, path, body: body)
    end

    private

    # Yields each record when given a block (so the caller can stop early),
    # otherwise returns them all.
    def paginate(path, params = {})
      records = []
      page = get(path, params)
      loop do
        page["data"].each do |record|
          block_given? ? yield(record) : records << record
        end
        next_url = page.dig("links", "next")
        break if next_url.nil?
        page = request(Net::HTTP::Get, next_url)
      end
      records
    end

    def token
      Spaceship::ConnectAPI::Token.create(key_id: @key_id, issuer_id: @issuer_id, key: @key).text
    end

    def request(klass, path_or_url, params: {}, body: nil, attempts: 3)
      uri = URI(path_or_url.start_with?("http") ? path_or_url : API_ROOT + path_or_url)
      uri.query = URI.encode_www_form(params) unless params.empty?

      attempts.times do |attempt|
        req = klass.new(uri)
        req["Authorization"] = "Bearer #{token}"
        if body
          req["Content-Type"] = "application/json"
          req.body = JSON.generate(body)
        end

        response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
        code = response.code.to_i
        return JSON.parse(response.body.to_s.empty? ? "{}" : response.body) if code.between?(200, 299)

        # Retry what is plausibly transient; anything else is a real answer.
        if (code == 429 || code >= 500) && attempt < attempts - 1
          @log.call("#{klass::METHOD} #{uri.path} returned #{code}, retrying")
          sleep(5 * (attempt + 1))
          next
        end
        raise Error, "#{klass::METHOD} #{uri.path} returned #{code}: #{response.body}"
      end
    end
  end
end
