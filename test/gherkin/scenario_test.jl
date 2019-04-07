using ExecutableSpecifications.Gherkin: issuccessful, parsescenario!, Given, When, Then, ByLineParser, ScenarioStep

@testset "Scenario             " begin
    @testset "Scenario has a Given step; the parsed scenario has a Given struct" begin
        text = """
        Scenario: Some description
            Given a precondition
        """

        byline = ByLineParser(text)
        result = parsescenario!(byline)

        @test issuccessful(result)
        scenario = result.value

        @test scenario.steps == ScenarioStep[Given("a precondition")]
    end

    @testset "Scenario has a When step; the parsed scenario has a When struct" begin
        text = """
        Scenario: Some description
            When some action
        """

        byline = ByLineParser(text)
        result = parsescenario!(byline)

        @test issuccessful(result)
        scenario = result.value

        @test scenario.steps == ScenarioStep[When("some action")]
    end

    @testset "Scenario has a Then step; the parsed scenario has a Then struct" begin
        text = """
        Scenario: Some description
            Then a postcondition
        """

        byline = ByLineParser(text)
        result = parsescenario!(byline)

        @test issuccessful(result)
        scenario = result.value

        @test scenario.steps == ScenarioStep[Then("a postcondition")]
    end

    @testset "Scenario has an And following a Given; the And step becomes a Given" begin
        text = """
        Scenario: Some description
            Given a precondition
              And another precondition
        """

        byline = ByLineParser(text)
        result = parsescenario!(byline)

        @test issuccessful(result)
        scenario = result.value

        @test scenario.steps == ScenarioStep[Given("a precondition"),
                                                 Given("another precondition")]
    end

    @testset "Scenario has an And following a When; the And step becomes a When" begin
        text = """
        Scenario: Some description
            When some action
             And another action
        """

        byline = ByLineParser(text)
        result = parsescenario!(byline)

        @test issuccessful(result)
        scenario = result.value

        @test scenario.steps == ScenarioStep[When("some action"),
                                                 When("another action")]
    end

    @testset "Scenario has an And following a Then; the And step becomes a Then" begin
        text = """
        Scenario: Some description
            Then some postcondition
             And another postcondition
        """

        byline = ByLineParser(text)
        result = parsescenario!(byline)

        @test issuccessful(result)
        scenario = result.value

        @test scenario.steps == ScenarioStep[Then("some postcondition"),
                                                 Then("another postcondition")]
    end

    @testset "Scenario is not terminated by newline; EOF is also an OK termination" begin
        text = """
        Scenario: Some description
            Then some postcondition
            And another postcondition"""

        byline = ByLineParser(text)
        result = parsescenario!(byline)

        @test issuccessful(result)
    end

    @testset "Malformed scenarios" begin
        @testset "And as a first step; Expected Given, When, or Then before that" begin
            text = """
            Scenario: Some description
                And another postcondition
            """

            byline = ByLineParser(text)
            result = parsescenario!(byline)

            @test !issuccessful(result)
            @test result.reason == :leading_and
            @test result.expected == :specific_step
            @test result.actual == :and_step
        end

        @testset "Given after a When; Expected When or Then" begin
            text = """
            Scenario: Some description
                 When some action
                Given some precondition
            """

            byline = ByLineParser(text)
            result = parsescenario!(byline)

            @test !issuccessful(result)
            @test result.reason == :bad_step_order
            @test result.expected == :NotGiven
            @test result.actual == :Given
        end

        @testset "Given after Then; Expected Then" begin
            text = """
            Scenario: Some description
                Then some postcondition
                Given some precondition
            """

            byline = ByLineParser(text)
            result = parsescenario!(byline)

            @test !issuccessful(result)
            @test result.reason == :bad_step_order
            @test result.expected == :NotGiven
            @test result.actual == :Given
        end

        @testset "When after Then; Expected Then" begin
            text = """
            Scenario: Some description
                Then some postcondition
                When some action
            """

            byline = ByLineParser(text)
            result = parsescenario!(byline)

            @test !issuccessful(result)
            @test result.reason == :bad_step_order
            @test result.expected == :NotWhen
            @test result.actual == :When
        end

        @testset "Invalid step definition NotAStep; Expected a valid step definition" begin
            text = """
            Scenario: Some description
                NotAStep some more text
            """

            byline = ByLineParser(text)
            result = parsescenario!(byline)

            @test !issuccessful(result)
            @test result.reason == :invalid_step
            @test result.expected == :step_definition
            @test result.actual == :invalid_step_definition
        end

        @testset "A step definition without text; Expected a valid step definition" begin
            text = """
            Scenario: Some description
                Given
            """

            byline = ByLineParser(text)
            result = parsescenario!(byline)

            @test !issuccessful(result)
            @test result.reason == :invalid_step
            @test result.expected == :step_definition
            @test result.actual == :invalid_step_definition
        end
    end

    @testset "Block text" begin
        @testset "Block text in a Given; Block text is present in step" begin
            text = """
            Scenario: Some description
                Given some precondition
                \"\"\"
                This is block text.
                There are two lines.
                \"\"\"
            """

            byline = ByLineParser(text)
            result = parsescenario!(byline)

            @test issuccessful(result)
            scenario = result.value

            @test scenario.steps[1].block_text == """
            This is block text.
            There are two lines."""
        end

        @testset "Another block text in a Given; Block text is present in step" begin
            text = """
            Scenario: Some description
                Given some precondition
                \"\"\"
                This is another block text.
                There are three lines.
                This is the last line.
                \"\"\"
            """

            byline = ByLineParser(text)
            result = parsescenario!(byline)

            @test issuccessful(result)
            scenario = result.value

            @test scenario.steps[1].block_text == """
            This is another block text.
            There are three lines.
            This is the last line."""
        end

        @testset "Block text in a When step; Block text is present in step" begin
            text = """
            Scenario: Some description
                When some action
                \"\"\"
                This is block text.
                \"\"\"
            """

            byline = ByLineParser(text)
            result = parsescenario!(byline)

            @test issuccessful(result)
            scenario = result.value

            @test scenario.steps[1] == When("some action"; block_text="""This is block text.""")
        end

        @testset "Block text in a Then step; Block text is present in step" begin
            text = """
            Scenario: Some description
                Then some postcondition
                \"\"\"
                This is block text.
                \"\"\"
            """

            byline = ByLineParser(text)
            result = parsescenario!(byline)

            @test issuccessful(result)
            scenario = result.value

            @test scenario.steps[1] == Then("some postcondition"; block_text="""This is block text.""")
        end
    end
end