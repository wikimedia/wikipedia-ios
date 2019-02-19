# Event logging
Note: Testing event logging requires `labs` access to `deployment-eventlog05.eqiad.wmflabs`

To test event logging:
- ensure event logging is enabled via `Gear icon > Send usage reports`
- select `Event Logging Dev Debug` scheme in Xcode
- get the app install id:
  - run app in the simulator
  - pause
  - paste `po [WMFEventLoggingService sharedInstance].appInstallID` in the Xcode console and copy the resulting string
- ssh to labs: `ssh deployment-eventlog05.eqiad.wmflabs`
- [tail](https://en.wikipedia.org/wiki/Tail_%28Unix%29) the following files (`tail` keeps stream open and prints last few lines of a file any time it changes) with the app install id and the id of the schema being tested (from [MPopov](https://meta.wikimedia.org/wiki/User:MPopov_%28WMF%29/Notes/Android_app_analytics#Verifying)):
  - `/srv/log/eventlogging/all-events.log`
    - only has events which have been validated against the appropriate schemas
  - `/srv/log/eventlogging/client-side-events.log`
    - has all incoming events (as raw, encoded URI query strings) regardless of their validity
  - `/var/log/eventlogging/eventlogging-processor@client-side-00.log`
  - `/var/log/eventlogging/eventlogging-processor@client-side-01.log`
    - if there are any issues with the incoming events or their validation, there will be detailed messages in the two `eventlogging-processor@-client-side-XX` logs  
  
  Example:
  - `tail -f /srv/log/eventlogging/all-events.log | grep "<app install id>" | grep "<schema id>"`