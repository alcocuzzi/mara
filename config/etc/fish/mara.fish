for script_path in "/app/scripts/"*
    set script_name (basename $script_path)
    complete -c mara -a $script_name
end