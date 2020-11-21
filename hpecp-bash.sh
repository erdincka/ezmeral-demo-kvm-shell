_hpecp_complete()
    {
    local cur prev BASE_LEVEL

    COMPREPLY=()
    cur=${COMP_WORDS[COMP_CWORD]}
    prev=${COMP_WORDS[COMP_CWORD-1]}

    MODULE=${COMP_WORDS[1]}

    COMP_WORDS_AS_STRING=$(IFS=. ; echo "${COMP_WORDS[*]}")

    # if last input was > for redirecting to a file
    # perform file and directory autocompletion
    if echo "${prev}" | grep -q '>'
    then
        _filedir;
        return
    fi



    declare -A MODULE_COLUMNS=(
            ['catalog']="label_name label_description self_href feed distro_id version timestamp isdebug osclass logo_checksum logo_url documentation_checksum documentation_mimetype documentation_file state state_info"
            ['config']=""
            ['install']=""
            ['epicworker']="id state ip purpose href _links"
            ['k8sworker']="id status hostname ipaddr href _links"
            ['k8scluster']="id name description k8s_version addons created_by_user_id created_by_user_name created_time k8shosts_config admin_kube_config dashboard_token api_endpoint_access dashboard_endpoint_access cert_data status status_message _links"
            ['tenant']="id name description status tenant_type external_user_groups"
            ['gateway']="id hacapable propinfo approved_worker_pubkey schedule ip proxy_nodes_hostname hostname state status_info purpose sysinfo tags"
            ['lock']=""
            ['license']=""
            ['httpclient']=""
            ['user']="id name description is_group_added_user is_external is_service_account default_tenant is_siteadmin"
            ['role']="id name description"
            ['datatap']="id name description type status"
    )


    # list has uniform behaviour as it is implemented in base.BaseProxy
    if [[ "${COMP_WORDS[2]}" == "list" ]];
    then

        # if 'list' was the last word
        if [[ "${prev}" == "list" ]];
        then
            COMPREPLY=( $(compgen -W "--columns --query" -- $cur) )
            return
        fi



        # '--columns' was the last word and user is entering column names
        if [[ "${COMP_WORDS[3]}" == "--columns"* && ${#COMP_WORDS[@]} -le 5 ]];
        then
            declare -a COLUMNS=(${MODULE_COLUMNS[$MODULE]})

            local realcur prefix
            realcur=${cur##*,} # everything after the last comma, e.g. a,b,c,d -> d
            prefix=${cur%,*}   # everything before the lat comma, e.g. a,b,c,d -> a,b,c

            if [[ "$cur" == *,* ]];
            then
                IFS=',' ENTERED_COLUMNS_LIST=($prefix)
                unset IFS
            else
                IFS=',' ENTERED_COLUMNS_LIST=($prev)
                unset IFS
            fi

            for COLUMN in ${COLUMNS[@]}; do
                for ENTERED_COLUMN in ${ENTERED_COLUMNS_LIST[@]}; do
                    if [[ "${ENTERED_COLUMN}" == "${COLUMN}" ]]
                    then
                        # remove columns already entered by user
                        COLUMNS=(${COLUMNS[*]//$ENTERED_COLUMN/})
                    fi
                done
            done

            if [[ "$cur" == *,* ]];
            then
                COMPREPLY=( $(compgen -W "${COLUMNS[*]}" -P "${prefix}," -S "," -- ${realcur}) )
                compopt -o nospace
                return
            else
                COMPREPLY=( $(compgen -W "${COLUMNS[*]}" -S "," -- ${realcur}) )
                compopt -o nospace
                return
            fi
        fi

        # user has finished entering column list or query
        if [[ ${#COMP_WORDS[@]} == 6 ]];
        then
            COMPREPLY=( $(compgen -W "--output" -- $cur) )
            return
        fi

        if [[ "${COMP_WORDS[5]}" == "--output"*  ]];
        then
            if [[ "${COMP_WORDS[3]}" == "--columns"*  ]];
            then
                COMPREPLY=( $(compgen -W "table text" -- $cur) )
                return
            else
                COMPREPLY=( $(compgen -W "json json-pp text" -- $cur) )
                return
            fi
        fi

        return
    fi

    # if the last parameter was --*file perform
    # file and directory autocompletion
    if echo "${prev}" | grep -q '\-\-.*file$'
    then
        _filedir;
        return
    fi

    # if last input was > for redirecting to a file
    # perform file and directory autocompletion
    if echo "${prev}" | grep -q '>'
    then
        _filedir;
        return
    fi

    case "$COMP_WORDS_AS_STRING" in

        *"hpecp.catalog.wait-for-state."*)
            PARAM_NAMES="--id --states --timeout-secs"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.catalog.refresh."*)
            PARAM_NAMES="--catalog-id"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
                # do nothing - already handled above
        *"hpecp.catalog.install."*)
            PARAM_NAMES="--catalog-id"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.catalog.get."*)
            PARAM_NAMES="--id --output --params"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.catalog.examples."*)
            PARAM_NAMES=""
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.catalog.delete."*)
            PARAM_NAMES="--id"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.catalog"*)
            COMPREPLY=( $(compgen -W "wait-for-state refresh list install get examples delete" -- $cur) )
            ;;
        *"hpecp.config.get."*)
            PARAM_NAMES="--output --query"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.config.examples."*)
            PARAM_NAMES=""
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.config"*)
            COMPREPLY=( $(compgen -W "get examples" -- $cur) )
            ;;
        *"hpecp.install.set-gateway-ssl."*)
            PARAM_NAMES="--cert-file --cert-content --cert-file-name --key-file --key-content --key-file-name"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.install.get."*)
            PARAM_NAMES="--output --query"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.install.examples."*)
            PARAM_NAMES=""
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.install"*)
            COMPREPLY=( $(compgen -W "set-gateway-ssl get examples" -- $cur) )
            ;;
        *"hpecp.epicworker.wait-for-state."*)
            PARAM_NAMES="--id --states --timeout-secs"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.epicworker.states."*)
            PARAM_NAMES=""
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.epicworker.set-storage."*)
            PARAM_NAMES="--id --ephemeral-disks --persistent-disks"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
                # do nothing - already handled above
        *"hpecp.epicworker.get."*)
            PARAM_NAMES="--id --output --params"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.epicworker.delete."*)
            PARAM_NAMES="--id --wait-for-delete-sec"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.epicworker.create-with-ssh-key."*)
            PARAM_NAMES="--ip --ssh-key --ssh-key-file --tags --ephemeral-disks --persistent-disks --wait-for-operation-secs"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.epicworker"*)
            COMPREPLY=( $(compgen -W "wait-for-state states set-storage list get delete create-with-ssh-key" -- $cur) )
            ;;
        *"hpecp.k8sworker.wait-for-status."*)
            PARAM_NAMES="--id --status --timeout-secs"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.k8sworker.statuses."*)
            PARAM_NAMES=""
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.k8sworker.set-storage."*)
            PARAM_NAMES="--id --ephemeral-disks --persistent-disks"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
                # do nothing - already handled above
        *"hpecp.k8sworker.get."*)
            PARAM_NAMES="--id --output --params"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.k8sworker.delete."*)
            PARAM_NAMES="--id --wait-for-delete-sec"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.k8sworker.create-with-ssh-key."*)
            PARAM_NAMES="--ip --ssh-key --ssh-key-file --tags --ephemeral-disks --persistent-disks --wait-for-operation-secs"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.k8sworker"*)
            COMPREPLY=( $(compgen -W "wait-for-status statuses set-storage list get delete create-with-ssh-key" -- $cur) )
            ;;
        *"hpecp.k8scluster.wait-for-status."*)
            PARAM_NAMES="--id --status --timeout-secs"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.k8scluster.upgrade-cluster."*)
            PARAM_NAMES="--id --k8s-upgrade-version --worker-upgrade-percent"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.k8scluster.statuses."*)
            PARAM_NAMES=""
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
                # do nothing - already handled above
        *"hpecp.k8scluster.k8smanifest."*)
            PARAM_NAMES=""
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.k8scluster.k8s-supported-versions."*)
            PARAM_NAMES="--output --major-filter --minor-filter --patch-filter"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.k8scluster.import-generic-cluster-with-json."*)
            PARAM_NAMES="--json-file-path --json-content"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.k8scluster.import-generic-cluster."*)
            PARAM_NAMES="--name --description --pod-dns-domain --server-url --ca --bearer-token"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.k8scluster.get-installed-addons."*)
            PARAM_NAMES="--id"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.k8scluster.get-available-addons."*)
            PARAM_NAMES="--id --k8s-version"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.k8scluster.get."*)
            PARAM_NAMES="--id --output --params"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.k8scluster.examples."*)
            PARAM_NAMES=""
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.k8scluster.delete."*)
            PARAM_NAMES="--id --wait-for-delete-sec"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.k8scluster.dashboard-url."*)
            PARAM_NAMES="--id"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.k8scluster.dashboard-token."*)
            PARAM_NAMES="--id"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.k8scluster.create."*)
            PARAM_NAMES="--name --k8shosts-config --description --k8s-version --pod-network-range --service-network-range --pod-dns-domain --persistent-storage-local --persistent-storage-nimble-csi --addons"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.k8scluster.admin-kube-config."*)
            PARAM_NAMES="--id"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.k8scluster.add-addons."*)
            PARAM_NAMES="--id --addons --wait-for-ready-sec"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.k8scluster"*)
            COMPREPLY=( $(compgen -W "wait-for-status upgrade-cluster statuses list k8smanifest k8s-supported-versions import-generic-cluster-with-json import-generic-cluster get-installed-addons get-available-addons get examples delete dashboard-url dashboard-token create admin-kube-config add-addons" -- $cur) )
            ;;
        *"hpecp.tenant.wait-for-status."*)
            PARAM_NAMES="--id --status --timeout-secs"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.tenant.users."*)
            PARAM_NAMES="--id --output --columns --query"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
                # do nothing - already handled above
        *"hpecp.tenant.k8skubeconfig."*)
            PARAM_NAMES=""
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.tenant.get-external-user-groups."*)
            PARAM_NAMES="--tenant-id"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.tenant.get."*)
            PARAM_NAMES="--id --output --params"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.tenant.examples."*)
            PARAM_NAMES=""
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.tenant.delete-external-user-group."*)
            PARAM_NAMES="--tenant-id --group"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.tenant.delete."*)
            PARAM_NAMES="--id --wait-for-delete-sec"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.tenant.create."*)
            PARAM_NAMES="--name --description --tenant-type --k8s-cluster-id --is-namespace-owner --map-services-to-gateway --specified-namespace-name --adopt-existing-namespace --quota-memory --quota-persistent --quota-gpus --quota-cores --quota-disk --quota-tenant-storage"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.tenant.assign-user-to-role."*)
            PARAM_NAMES="--tenant-id --user-id --role-id"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.tenant.add-external-user-group."*)
            PARAM_NAMES="--tenant-id --group --role-id"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.tenant"*)
            COMPREPLY=( $(compgen -W "wait-for-status users list k8skubeconfig get-external-user-groups get examples delete-external-user-group delete create assign-user-to-role add-external-user-group" -- $cur) )
            ;;
        *"hpecp.gateway.wait-for-state."*)
            PARAM_NAMES="--id --states --timeout-secs"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.gateway.states."*)
            PARAM_NAMES=""
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
                # do nothing - already handled above
        *"hpecp.gateway.get."*)
            PARAM_NAMES="--id --output --params"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.gateway.delete."*)
            PARAM_NAMES="--id --wait-for-delete-sec"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.gateway.create-with-ssh-key."*)
            PARAM_NAMES="--ip --proxy-node-hostname --ssh-key --ssh-key-file --tags"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.gateway"*)
            COMPREPLY=( $(compgen -W "wait-for-state states list get delete create-with-ssh-key" -- $cur) )
            ;;
                # do nothing - already handled above
        *"hpecp.lock.delete-all."*)
            PARAM_NAMES="--timeout-secs"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.lock.delete."*)
            PARAM_NAMES="--id"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.lock.create."*)
            PARAM_NAMES="--reason --timeout-secs"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.lock"*)
            COMPREPLY=( $(compgen -W "list delete-all delete create" -- $cur) )
            ;;
        *"hpecp.license.register."*)
            PARAM_NAMES="--server-filename"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.license.platform-id."*)
            PARAM_NAMES=""
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
                # do nothing - already handled above
        *"hpecp.license.delete-all."*)
            PARAM_NAMES=""
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.license.delete."*)
            PARAM_NAMES="--license-key"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.license"*)
            COMPREPLY=( $(compgen -W "register platform-id list delete-all delete" -- $cur) )
            ;;
        *"hpecp.httpclient.put."*)
            PARAM_NAMES="--url --json-file"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.httpclient.post."*)
            PARAM_NAMES="--url --json-file"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.httpclient.get."*)
            PARAM_NAMES="--url"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.httpclient.delete."*)
            PARAM_NAMES="--url"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.httpclient"*)
            COMPREPLY=( $(compgen -W "put post get delete" -- $cur) )
            ;;
                # do nothing - already handled above
        *"hpecp.user.get."*)
            PARAM_NAMES="--id --output --params"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.user.examples."*)
            PARAM_NAMES=""
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.user.delete."*)
            PARAM_NAMES="--id --wait-for-delete-sec"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.user.create."*)
            PARAM_NAMES="--name --password --description --is-external"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.user"*)
            COMPREPLY=( $(compgen -W "list get examples delete create" -- $cur) )
            ;;
                # do nothing - already handled above
        *"hpecp.role.get."*)
            PARAM_NAMES="--id --output --params"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.role.examples."*)
            PARAM_NAMES=""
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.role.delete."*)
            PARAM_NAMES="--id --wait-for-delete-sec"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.role"*)
            COMPREPLY=( $(compgen -W "list get examples delete" -- $cur) )
            ;;
        *"hpecp.datatap.wait-for-state."*)
            PARAM_NAMES="--id --states --timeout-secs"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
                # do nothing - already handled above
        *"hpecp.datatap.get."*)
            PARAM_NAMES="--id --output --params"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.datatap.delete."*)
            PARAM_NAMES="--id --wait-for-delete-sec"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.datatap.create-hdfs-with-kerberos."*)
            PARAM_NAMES="--name --description --path-from-endpoint --kdc-data-host --kdc-data-port --realm --client-principal --browse-only --host --keytab --backup-host --type --port --read-only"
            for PARAM in ${PARAM_NAMES[@]}; do
                PARAM="${PARAM//''}"
                for WORD in ${COMP_WORDS[@]}; do
                    if [[ "${WORD}" == "${PARAM}" ]]
                    then
                        # remove parameters already entered by user
                        PARAM_NAMES=${PARAM_NAMES//$WORD/}
                    fi
                done
            done
            COMPREPLY=( $(compgen -W "$PARAM_NAMES" -- $cur) )
            ;;
        *"hpecp.datatap"*)
            COMPREPLY=( $(compgen -W "wait-for-state list get delete create-hdfs-with-kerberos" -- $cur) )
            ;;
        *"hpecp.autocomplete.bash"*)
            COMPREPLY=( )
            ;;
        *"hpecp.autocomplete"*)
            COMPREPLY=( $(compgen -W "bash" -- $cur) )
            ;;
        *"hpecp"*)
            COMPREPLY=( $(compgen -W "autocomplete configure-cli version catalog config install epicworker k8sworker k8scluster tenant gateway lock license httpclient user role datatap" -- $cur) )
            ;;
    esac
    return 0
} &&
complete -F _hpecp_complete hpecp
