version: 0.2

phases:
  pre_build:
    commands:
      - BUILD_CONDITION=$(cat ci.txt)
      - PR_NUMBER=$(cat pr.txt)
      - SRC_CHANGED=$(cat src_changed.txt)
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
        aws lambda update-function-code --function-name $FUNCTION_NAME --image-uri $IMAGE_URI || exit 1
        aws lambda wait function-updated --function-name $FUNCTION_NAME
        TARGET_VERSION=$(aws lambda publish-version --function-name $FUNCTION_NAME --query 'Version' --output text)
        aws lambda wait published-version-active --function-name $FUNCTION_NAME --qualifier $TARGET_VERSION
        CURRENT_VERSION=$(aws lambda get-alias --function-name $FUNCTION_NAME --name live --query 'FunctionVersion' --output text)
        echo $APPSPEC > appspec.json
        sed -i -E 's/<FUNCTION_NAME>/'$FUNCTION_NAME'/' appspec.json
        sed -i -E 's/<CURRENT_VERSION>/'$CURRENT_VERSION'/' appspec.json
        sed -i -E 's/<TARGET_VERSION>/'$TARGET_VERSION'/' appspec.json
        cat appspec.json

artifacts:
  files:
    - appspec.json
  discard-paths: yes
  
