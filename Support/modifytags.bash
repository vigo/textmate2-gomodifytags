#!/usr/bin/env bash
#
# Created by Uğur Özyılmazel on 2023-08-23.
# Copyright (c) 2023 VB YAZILIM. All rights reserved.

set -e
set -o pipefail
set -o errexit
set -o nounset

exit_show_tool_tip () { echo -n -e "$1" >&1; exit 206; }

modify_tags(){
    if [ -z ${TM_FILEPATH+x} ]; then
        exit_show_tool_tip "you must save the file first!"
    fi

    if [[ ! "${TM_SELECTION}" == *-* ]]; then
        exit_show_tool_tip "your selection is empty, please select lines"
    fi

    if [ -z "$(command -v gomodifytags)" ]; then
        exit_show_tool_tip "please make sure:\n\nyou have installed gomodifytags\nand set TM PATH variable (go env GOPATH)"
    fi

    STRUCT_NAME=$(awk '/type [A-Z][a-zA-Z]* struct {/{print $2}' "${TM_FILEPATH}")

    [ -z "${STRUCT_NAME}" ] && return 1
    
    local tag_name="${1}"
    local action="${2}"
    local option_action="${3:-}"
    local option_value="${4:-}"

    case "${action}" in
        "-add-tags"|"-remove-tags")
            args=(-file "${TM_FILEPATH}" -struct "${STRUCT_NAME}" "${action}" "${tag_name}")
            
            case "${option_action}" in
                "-add-options"|"-remove-options")
                    args+=("${option_action}" "${option_value}")
                    ;;
            esac
            
            if [[ "${action}" == "-add-tags" ]]; then
                case "${tag_name}" in
                    "gorm")
                        args+=(-template "column:{field};type:TYPE;")
                        ;;
                esac
            fi
            
            args+=(--skip-unexported)
            
            ;;
        "-clear-tags")
            args=(-file "${TM_FILEPATH}" -struct "${STRUCT_NAME}" -clear-tags)
            ;;
    esac
    
    MODIFIED_STRUCT=$(gomodifytags "${args[@]}")


    echo "${MODIFIED_STRUCT}" | awk -v struct_name="${STRUCT_NAME}" '
    /type '"${STRUCT_NAME}"' struct {/ {print; p=1; count=1; next}
    p {
      print
      for(i=1; i<=NF; i++) {
        if ($i ~ /\{/) count++
        if ($i ~ /\}/) count--
      }
      if (count == 0) exit
    }'
    return 0
}




