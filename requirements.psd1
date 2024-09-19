# This file enables modules to be automatically managed by the Functions service.
# See https://aka.ms/functionsmanageddependency for additional information.
#
@{
    # For latest supported version, go to 'https://www.powershellgallery.com/packages/Az'. Uncomment the next line and replace the MAJOR_VERSION, e.g., 'Az' = '5.*'
    #'Az' = '12.*'
    'Az.Accounts'            = '3.0.4'
    'Az.ApplicationInsights' = '2.2.5'
    'powershell-yaml'        = '0.4.4' # Must use this because never uses netstandard 2.x which is not supported by Azure Functions.
}
