#!/bin/bash

NAME=$1

# Dependency, RootFeature 파일 경로
DEPENDENCY_FILE="./Tuist/ProjectDescriptionHelpers/Extension/Dependency+Domain.swift"

# 이름 전달 확인
if [ -z "$NAME" ]; then
    echo "🔴 모듈명이 제대로 들어오지 않았습니다. 🔴"
    exit 1
fi

# Dependency 파일이 존재하는지 확인
if [ ! -f "$DEPENDENCY_FILE" ]; then
    echo "🔴 $DEPENDENCY_FILE 이 없습니다."
    exit 1
fi

# Dependency에 추가할 Struct
NEW_DEPENDENCY_STRUCT="        public struct $NAME {}"

# Dependency에 추가할 Extension
NEW_DEPENDENCY_EXTENSION=$(cat <<EOF

public extension TargetDependency.Domains.$NAME {
    static let name = "$NAME"
    
    static let Domain = TargetDependency.Domains.project(name: "\(name)Domain")
}
EOF
)

# Root에 추가할 Dependency
NEW_ROOT_DEPENDENCY="        .Domains.$NAME.Domain,"

# Feature Struct 추가
sed -i '' "/struct Domains {/a\\
$NEW_DEPENDENCY_STRUCT
" "$DEPENDENCY_FILE"

# Feature Extension 추가
echo "$NEW_DEPENDENCY_EXTENSION" >> "$DEPENDENCY_FILE"

