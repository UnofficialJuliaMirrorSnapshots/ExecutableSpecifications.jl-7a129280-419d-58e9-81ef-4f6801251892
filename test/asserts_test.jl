using ExecutableSpecifications
using ExecutableSpecifications.Gherkin

@testset "Asserts              " begin
    @testset "Assert failure; Assert is 1 == 2; Failure has human readable string 1 == 2" begin
        try
            @expect 1 == 2
        catch ex
            @test ex.assertion == "1 == 2"
        end
    end

    @testset "Assert failure in included file; Assert is 1 == 2; Failure has human readable string 1 == 2" begin
        matcher = ExecutableSpecifications.FromMacroStepDefinitionMatcher("""
            using ExecutableSpecifications

            @given "some precondition" begin
                @expect 1 == 2
            end
        """)
        given = Gherkin.Given("some precondition")
        context = ExecutableSpecifications.StepDefinitionContext()

        stepdefinition = ExecutableSpecifications.findstepdefinition(matcher, given)

        stepfailed = stepdefinition.definition(context)

        @test stepfailed.assertion == "1 == 2"
    end

    @testset "Assert failure in included file; Assert is isempty([1]); Failure has human readable string isempty([1])" begin
        matcher = ExecutableSpecifications.FromMacroStepDefinitionMatcher("""
            using ExecutableSpecifications

            @given "some precondition" begin
                @expect isempty([1])
            end
        """)
        given = Gherkin.Given("some precondition")
        context = ExecutableSpecifications.StepDefinitionContext()

        stepdefinition = ExecutableSpecifications.findstepdefinition(matcher, given)

        stepfailed = stepdefinition.definition(context)

        @test stepfailed.assertion == "isempty([1])"
    end
end