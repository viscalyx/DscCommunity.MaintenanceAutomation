BeforeAll {
    . $PSScriptRoot/../Relabeler/run.ps1
}

Describe "HttpTrigger1" {
    It "Returns a successful response" {
        $request = @{
            Query = @{}
        }
        $result = HttpTrigger1 $request
        $result.StatusCode | Should -Be 200
        $result.Body | Should -Be "This HTTP triggered function executed successfully."
    }
}
