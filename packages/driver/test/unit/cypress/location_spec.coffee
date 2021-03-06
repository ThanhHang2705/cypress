require("../../support/unit_spec_helper")

_ = require("lodash")
Promise = require("bluebird")
$Location = require("#{src}/cypress/location")

urls = {
  blank:    "about:blank"
  cypress:  "http://0.0.0.0:2020/__/#/tests/app.coffee"
  signin:   "http://localhost:2020/signin"
  users:    "http://localhost:2020/users/1"
  google:   "https://www.google.com"
  ember:    "http://localhost:2020/index.html#/posts"
  app:      "http://localhost:2020/app/#posts/1"
  search:   "http://localhost:2020/search?q=books"
  pathname: "http://localhost:2020/app/index.html"
  local:    "http://127.0.0.1:8080/foo/bar"
  stack:    "https://stackoverflow.com/"
  trailHash:"http://localhost:3500/index.html?foo=bar#"
  email:    "http://localhost:3500/?email=brian@cypress.io"
}

describe "src/cypress/location", ->
  beforeEach ->
    @setup = (remote) =>
      new $Location(urls[remote])

  context "#getHash", ->
    it "returns the hash fragment prepended with #", ->
      str = @setup("app").getHash()
      expect(str).to.eq "#posts/1"

    it "returns empty string when no hash", ->
      str = @setup("signin").getHash()
      expect(str).to.eq ""

    it "returns empty when only hash is present", ->
      ## its weird, but this matches current browser behavior
      str = @setup("hash").getHash()
      expect(str).to.eq("")

  context "#getHref", ->
    it "returns the full url", ->
      str = @setup("signin").getHref()
      expect(str).to.eq "http://localhost:2020/signin"

    it "does not apply a leading slash after removing query params", ->
      str = @setup("ember").getHref()
      expect(str).to.eq "http://localhost:2020/index.html#/posts"

    it "includes hash even when hash is empty", ->
      str = @setup("trailHash").getHref()
      expect(str).to.eq(urls.trailHash)

  context "#getHost", ->
    it "returns port if port is present", ->
      str = @setup("signin").getHost()
      expect(str).to.eq("localhost:2020")

    it "omits port if port is blank", ->
      str = @setup("google").getHost()
      expect(str).to.eq("www.google.com")

  context "#getHostName", ->
    it "returns host without port", ->
      str = @setup("signin").getHostName()
      expect(str).to.eq("localhost")

  context "#getOrigin", ->
    it "returns the origin including port", ->
      str = @setup("signin").getOrigin()
      expect(str).to.eq("http://localhost:2020")

    it "returns the origin without port", ->
      str = @setup("google").getOrigin()
      expect(str).to.eq("https://www.google.com")

    it "returns the origin as null for about:blank", ->
      origin = @setup("blank").getOrigin()
      expect(origin).to.eq(null)

  context "#getPathName", ->
    it "returns the path", ->
      str = @setup("signin").getPathName()
      expect(str).to.eq("/signin")

    it "returns a / with no path", ->
      str = @setup("google").getPathName()
      expect(str).to.eq("/")

    it "returns the full pathname without a host", ->
      str = @setup("pathname").getPathName()
      expect(str).to.eq("/app/index.html")

  context "#getPort", ->
    it "returns the port", ->
      str = @setup("signin").getPort()
      expect(str).to.eq("2020")

    it "returns empty string if port is blank", ->
      str = @setup("google").getPort()
      expect(str).to.eq("")

  context "#getProtocol", ->
    it "returns the http protocol", ->
      str = @setup("signin").getProtocol()
      expect(str).to.eq("http:")

    it "returns the https protocol", ->
      str = @setup("google").getProtocol()
      expect(str).to.eq("https:")

  context "#getSearch", ->
    it "returns the search params with ? prepended", ->
      str = @setup("search").getSearch()
      expect(str).to.eq("?q=books")

    it "returns an empty string with no seach params", ->
      str = @setup("google").getSearch()
      expect(str).to.eq("")

  context "#getToString", ->
    it "returns the toString function", ->
      str = @setup("signin").getToString()
      expect(str).to.eq("http://localhost:2020/signin")

  context "#getOriginPolicy", ->
    it "handles ip addresses", ->
      str = @setup("local").getOriginPolicy()
      expect(str).to.eq("http://127.0.0.1:8080")

    it "handles 1 part localhost", ->
      str = @setup("users").getOriginPolicy()
      expect(str).to.eq("http://localhost:2020")

    it "handles 2 parts stack", ->
      str = @setup("stack").getOriginPolicy()
      expect(str).to.eq("https://stackoverflow.com")

    it "handles subdomains google", ->
      str = @setup("google").getOriginPolicy()
      expect(str).to.eq("https://google.com")

    it "issue: #255 two domains in the url", ->
      str = @setup("email").getOriginPolicy()
      expect(str).to.eq("http://localhost:3500")

  context ".create", ->
    it "returns an object literal", ->
      obj = $Location.create(urls.cypress, urls.signin)
      keys = ["hash", "href", "host", "hostname", "origin", "pathname", "port", "protocol", "search", "toString", "originPolicy", "superDomain"]
      expect(obj).to.have.keys(keys)

    it "can invoke toString function", ->
      obj = $Location.create(urls.signin)
      expect(obj.toString()).to.eq("http://localhost:2020/signin")

  context ".normalize", ->
    beforeEach ->
      @url = (source, expected) ->
        url = $Location.normalize(source)
        expect(url).to.eq(expected)

    describe "http urls", ->
      it "does not trim url", ->
        @url "http://github.com/foo/", "http://github.com/foo/"

      it "adds trailing slash to host", ->
        @url "https://localhost:4200", "https://localhost:4200/"

      it "does not mutate hash when setting path to slash", ->
        @url "http://0.0.0.0:3000#foo/bar", "http://0.0.0.0:3000/#foo/bar"

      it "does not mutate path when it exists", ->
        @url "http://localhost:3000/foo/bar", "http://localhost:3000/foo/bar"

    describe "http-less urls", ->
      it "trims url", ->
        @url "/index.html/", "/index.html/"

      it "does not add trailing slash with query params", ->
        @url "timeout?ms=1000", "timeout?ms=1000"

      it "does not strip path segments", ->
        @url "fixtures/sinon.html", "fixtures/sinon.html"

      it "formats urls with protocols", ->
        @url "beta.cypress.io", "http://beta.cypress.io/"

      it "formats urls with protocols and query params", ->
        @url "beta.cypress.io?foo=bar", "http://beta.cypress.io/?foo=bar"

      it "formats urls with 3 segments and path", ->
        @url "aws.amazon.com/s3/bucket", "http://aws.amazon.com/s3/bucket"

      it "formats urls with 4 segments", ->
        @url "foo.bar.co.uk", "http://foo.bar.co.uk/"

      it "formats urls with 4 segments and path", ->
        @url "foo.bar.co.uk/baz/quux", "http://foo.bar.co.uk/baz/quux"

    describe "localhost, 0.0.0.0, 127.0.0.1", ->
      _.each ["localhost", "0.0.0.0", "127.0.0.1"], (host) =>
        it "inserts http:// automatically for #{host}", ->
          @url "#{host}:4200", "http://#{host}:4200/"

    describe "localhost", ->
      it "keeps path / query params / hash around", ->
        @url "localhost:4200/foo/bar?quux=asdf#/main", "http://localhost:4200/foo/bar?quux=asdf#/main"

  context ".fullyQualifyUrl", ->
    beforeEach ->
      ## TODO: might be easier to stub out something on
      ## the $Location object -> or refactor for it
      ## to use a location getter module
      jsdom.reconfigure({url: "http://localhost:3500"})

      @normalize = (url) ->
        $Location.normalize(url)

    it "does not append trailing slash on a sub directory", ->
      url = @normalize("http://localhost:4200/app")
      url = $Location.fullyQualifyUrl(url)
      expect(url).to.eq "http://localhost:4200/app"

    it "does not append a trailing slash to url with hash", ->
      url = @normalize("http://localhost:4000/#/home")
      url = $Location.fullyQualifyUrl(url)
      expect(url).to.eq "http://localhost:4000/#/home"

    it "does not append a trailing slash to protocol-less url with hash", ->
      url = @normalize("www.github.com/#/home")
      url = $Location.fullyQualifyUrl(url)
      expect(url).to.eq "http://www.github.com/#/home"

    it "handles urls without a host", ->
      url = @normalize("index.html")
      url = $Location.fullyQualifyUrl(url)
      expect(url).to.eq "http://localhost:3500/index.html"

    it "does not insert trailing slash without a host", ->
      url = $Location.fullyQualifyUrl("index.html")
      expect(url).to.eq "http://localhost:3500/index.html"

    it "handles no host + query params", ->
      url = @normalize("timeout?ms=1000")
      url = $Location.fullyQualifyUrl(url)
      expect(url).to.eq "http://localhost:3500/timeout?ms=1000"

    it "does not strip off path", ->
      url = @normalize("fixtures/sinon.html")
      url = $Location.fullyQualifyUrl(url)
      expect(url).to.eq "http://localhost:3500/fixtures/sinon.html"
