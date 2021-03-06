describe "Project Mode", ->
  beforeEach ->
    cy.fixture("user").as("user")
    cy.fixture("config").as("config")
    cy.fixture("specs").as("specs")

    cy.visitIndex().then (win) =>
      { start, @ipc } = win.App

      cy.stub(@ipc, "onMenuClicked")
      cy.stub(@ipc, "onFocusTests")
      cy.stub(@ipc, "getOptions").resolves({projectPath: "/foo/bar"})
      cy.stub(@ipc, "updaterCheck").resolves(false)
      cy.stub(@ipc, "openProject").resolves(@config)
      cy.stub(@ipc, "getSpecs").yields(null, @specs)

      @getCurrentUser = @util.deferred()

      start()

  it "goes straight to project specs list", ->
    cy.shouldBeOnProjectSpecs()

  it "sets title as project path", ->
    cy.title().should("eq", "/foo/bar")

  it "shows project name in nav", ->
    cy.get('.left-nav').should("have.text", "bar")
