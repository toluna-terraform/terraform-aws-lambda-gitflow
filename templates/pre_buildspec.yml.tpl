version: 0.2

phases:
  install:
    runtime-versions:
      docker: 18
  pre_build:
    commands:
      - BUILD_CONDITION=$(cat ci.txt)
      - PR_NUMBER=$(cat pr.txt)
      - SRC_CHANGED=$(cat src_changed.txt)
      - |
        IFS=- read ENVIRONMENT COLOR <<< "${ENV_NAME}"
        aws ssm put-parameter --name /infra/${APP_NAME}-$ENVIRONMENT/merge_details --value  '[]' --type String --overwrite
      - |
        if [ "${PIPELINE_TYPE}" == "cd" ] || [[ "$SRC_CHANGED" == "false" && "${PIPELINE_TYPE}" != "cd" ]]; then
          export FROM_ENV="${FROM_ENV}"
        else
          export FROM_ENV=$(cat new_version.txt)
        fi
  build:
    commands:
      - |
        IMAGE_URI=$(printf "${ECR_REPO_URL}:%s" "$FROM_ENV")
        aws lambda update-function-code --function-name $FUNCTION_NAME-${ENV_NAME} --image-uri $IMAGE_URI || exit 1
        aws lambda wait function-updated --function-name $FUNCTION_NAME-${ENV_NAME}
        TARGET_VERSION=$(aws lambda publish-version --function-name $FUNCTION_NAME-${ENV_NAME} --query 'Version' --output text)
        CURRENT_VERSION=$(echo "$(($TARGET_VERSION-1))")
        echo $APPSPEC > appspec.json
        sed -i -E 's/<FUNCTION_NAME>/'$FUNCTION_NAME-${ENV_NAME}'/' appspec.json
        sed -i -E 's/<CURRENT_VERSION>/'$CURRENT_VERSION'/' appspec.json
        sed -i -E 's/<TARGET_VERSION>/'$TARGET_VERSION'/' appspec.json
        cat appspec.json

artifacts:
  files:
    - appspec.json
  discard-paths: yes
  