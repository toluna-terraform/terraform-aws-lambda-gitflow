{
    "version": 0.0,
    "Resources": [
        {
            "TargetLambda": {
                "Type": "AWS::Lambda::Function",
                "Properties": {
                    "Name": "<FUNCTION_NAME>",
                    "Alias": "live",
                    "CurrentVersion": "<CURRENT_VERSION>",
                    "TargetVersion": "<TARGET_VERSION>"
                }               
            }
        }
    ],
    "Hooks": [
        %{ if HOOKS }
        {
            "BeforeAllowTraffic": "${APP_NAME}-${ENV_TYPE}-test-framework-manager"
        },
        %{ endif }
        %{ if PIPELINE_TYPE != "dev" }
		{
            "AfterAllowTraffic": "${APP_NAME}-${ENV_TYPE}-merge-waiter"
        }
        %{ endif }
    ]
}
