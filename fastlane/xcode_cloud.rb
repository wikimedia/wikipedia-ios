require 'json'
require 'net/http'
require 'uri'
require 'fileutils'

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
    # log: progress messages. annotate: lines that must start at column 0
    # to become GitHub annotations (::error::), so they bypass fastlane's
    # timestamp prefix.
    def initialize(key_id:, issuer_id:, key:, log: ->(message) { puts(message) }, annotate: ->(line) { $stdout.puts(line) })
      @key_id = key_id
      @issuer_id = issuer_id
      @key = key
      @log = log
      @annotate = annotate
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
    # not finish within timeout seconds. On failure, the raised message
    # carries the failed action and its first error (see failure_report),
    # and log bundles are saved to logs_dir when one is given.
    def wait_for_build_run(id, timeout:, interval: 60, logs_dir: nil, sleeper: ->(s) { sleep(s) }, clock: -> { Time.now })
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
          detail = failure_report(id, dir: logs_dir)
          raise Error, "Xcode Cloud build #{attributes['number']} finished as #{status}" \
                       "#{detail ? " - #{detail}" : ''}. " \
                       "Errors are listed above#{logs_dir ? ' and the logs are attached to this run' : ''}; " \
                       "the full build is in App Store Connect > Xcode Cloud."
        end

        if clock.call >= deadline
          raise Error, "Xcode Cloud build #{attributes['number']} did not finish within #{timeout / 60} minutes (last state #{progress})"
        end
        sleeper.call(interval)
      end
    end

    # Explains a failed build run: for every action that did not succeed,
    # emits its errors (and the first few warnings) as GitHub annotations,
    # and downloads its log bundles into dir. Returns a one-line summary of
    # the first failure, or nil.
    #
    # This runs while a failure is already being reported, so nothing in it
    # may raise: each lookup that fails is logged and skipped, and the
    # caller's error stands.
    MAX_WARNINGS = 20
    REPOSITORY_ROOT = "/Volumes/workspace/repository/"

    def failure_report(run_id, dir: nil)
      summary = nil
      actions = safely("the build's actions") { paginate("/v1/ciBuildRuns/#{run_id}/actions", "limit" => "50") } || []
      actions.each do |action|
        attributes = action["attributes"] || {}
        status = attributes["completionStatus"]
        next if status == "SUCCEEDED"

        name = attributes["name"] || attributes["actionType"] || action["id"]
        @log.call("Xcode Cloud action #{name.inspect} finished as #{status}")

        issues = safely("the issues for #{name}") { paginate("/v1/ciBuildActions/#{action['id']}/issues", "limit" => "200") } || []
        errors, others = issues.partition { |i| %w[ERROR TEST_FAILURE].include?(i.dig("attributes", "issueType")) }
        errors.each { |issue| annotate("error", name, issue) }
        others.first(MAX_WARNINGS).each { |issue| annotate("warning", name, issue) }
        if others.length > MAX_WARNINGS
          @log.call("...and #{others.length - MAX_WARNINGS} more warnings")
        end

        first_error = errors.first&.dig("attributes", "message").to_s.lines.first&.strip
        summary ||= first_error.to_s.empty? ? "#{name} #{status&.downcase}" : "#{name}: #{first_error}"

        download_logs(action["id"], name, dir) if dir
      end
      summary
    rescue StandardError => e
      @log.call("Could not explain the failure: #{e.message}")
      summary
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

    def safely(what)
      yield
    rescue StandardError => e
      @log.call("Could not fetch #{what}: #{e.message}")
      nil
    end

    # One annotation per issue. GitHub reads these only at the start of a
    # line, with %, CR and LF escaped in the message.
    def annotate(level, action_name, issue)
      attributes = issue["attributes"] || {}
      message = attributes["message"].to_s
      source = attributes["fileSource"] || {}
      properties = ["title=Xcode Cloud: #{action_name}"]
      path = source["path"].to_s
      unless path.empty?
        properties << "file=#{path.delete_prefix(REPOSITORY_ROOT)}"
        properties << "line=#{source['lineNumber']}" if source["lineNumber"]
      end
      escaped = message.gsub("%", "%25").gsub("\r", "%0D").gsub("\n", "%0A")
      @annotate.call("::#{level} #{properties.map { |p| p.gsub(',', '%2C').gsub('::', '%3A%3A') }.join(',')}::#{escaped}")
    end

    # Log bundles are behind pre-signed URLs, so they are fetched without the
    # API token.
    def download_logs(action_id, action_name, dir)
      artifacts = safely("the artifacts for #{action_name}") { paginate("/v1/ciBuildActions/#{action_id}/artifacts", "limit" => "50") } || []
      logs = artifacts.select { |a| a.dig("attributes", "fileType") == "LOG_BUNDLE" }
      if logs.empty?
        @log.call("No log bundle for #{action_name}")
        return
      end
      FileUtils.mkdir_p(dir)
      logs.each do |artifact|
        attributes = artifact["attributes"]
        url = attributes["downloadUrl"]
        next if url.to_s.empty?
        file_name = "#{action_name}-#{attributes['fileName'] || artifact['id']}".gsub(%r{[^\w.\-]+}, "_")
        path = File.join(dir, file_name)
        safely("the log bundle #{file_name}") do
          fetch_to_file(URI(url), path)
          @log.call("Saved #{file_name} (#{File.size(path)} bytes)")
        end
      end
    end

    def fetch_to_file(uri, path, redirects: 3)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(Net::HTTP::Get.new(uri)) do |response|
          if response.is_a?(Net::HTTPRedirection) && redirects.positive?
            return fetch_to_file(URI(response["location"]), path, redirects: redirects - 1)
          end
          raise Error, "GET #{uri.host}#{uri.path} returned #{response.code}" unless response.is_a?(Net::HTTPSuccess)
          File.open(path, "wb") { |f| response.read_body { |chunk| f.write(chunk) } }
        end
      end
    end

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
