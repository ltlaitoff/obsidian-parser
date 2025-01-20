#!/usr/bin/bash

# set -x
shopt -s extglob

file_templates_dir="$HOME/.config/obsidian-parser/file-templates/"
file_template="base.md"

CONFIG_FILE="$HOME/.config/obsidian-parser/config.conf"

. $CONFIG_FILE

while [[ $# -gt 0 ]]; do
        case $1 in
        -ftf | --files-template-directory)
								file_templates_dir="$2"
                shift # past argument
                shift # past value
                ;;
        -ft | --file-template)
                file_template="$2"
                shift # past argument
                shift # past value
                ;;
        # -c | --config)
        #         CONFIG_FILE="$2"
        #         shift # past argument
        #         shift # past value
        #         ;;
        -* | --*)
                echo -e "Unknown option $1"
                exit 1
                ;;
        *)
                POSITIONAL_ARGS+=("$1") # save positional arg
                shift                   # past argument
                ;;

        esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

if [ -z "$1" ]; then
  echo "Error: You need to provide a input file path."
  echo "Usage: $0 <file_path>"
  exit 1
fi

if [ -z "$2" ]; then
  echo "Error: You need to provide a output directory path."
  echo "Usage: $0 <directory_path>"
  exit 1
fi

INPUT_FILE=$1
OUTPUT_DIRECTORY=$2

block_id=0
note_after_title=false

global_tags=""
global_file_template=""
global_source=""

note_title=""
note_text=""
note_global_tags=""
note_source=""
note_north=""
note_west=""
note_east=""
note_south=""

change_string_in_text () {
	echo "$1" | awk -v note_text="$2" -v pattern="$3" '{gsub("\\{\\{" pattern "\\}\\}", note_text); print}'
}

function save_file () {
	local file_name="$OUTPUT_DIRECTORY/${note_title}.md"
	
	mkdir -p $OUTPUT_DIRECTORY

	local file_template_content=""

	if [[ -n $global_file_template ]]; then
		template_file_path="$file_templates_dir$global_file_template.md"

		file_template_content=$(cat "$template_file_path")
	else
		file_template_content=$(cat "$file_templates_dir$file_template")
	fi

	file_template_content=$(change_string_in_text "$file_template_content" "$note_text" "note_text")
	file_template_content=$(change_string_in_text "$file_template_content" "$note_north" "note_north")
	file_template_content=$(change_string_in_text "$file_template_content" "$note_west" "note_west")
	file_template_content=$(change_string_in_text "$file_template_content" "$note_east" "note_east")
	file_template_content=$(change_string_in_text "$file_template_content" "$note_south" "note_south")

	local tags_output=''

	if [[ -n note_tags ]]; then
		tags_output=$global_tags;
	else
		tags_output=$note_tags;
	fi

	local source_output=''

	if [[ -n note_source ]]; then
		source_output=$global_source;
	else
		source_output=$note_source;
	fi

	file_template_content=$(change_string_in_text "$file_template_content" "$tags_output" "tags")
	file_template_content=$(change_string_in_text "$file_template_content" "$source_output" "source")

	echo "output to $file_name"

	echo -e "$file_template_content" > "$file_name"
}

while read line; do
	if [[ $line == "#" ]]; then
		save_file
		break
	fi

	if [[ $line == "---" && block_id -eq 0 ]]; then
		((block_id += 1))
		continue
	fi

	if [[ $line == "---" && block_id -gt 0 ]]; then
		((block_id += 1))

		save_file

		note_title=""
		note_text=""
		note_global_tags=""
		note_source=""
		note_north=""
		note_west=""
		note_east=""
		note_south=""
		note_after_title=false
		
		continue
	fi

	# Global parameters
	if [[ $block_id -eq 0 ]]; then 
		if [[ $line =~ ^tags:\ (.+) ]]; then
			global_tags="${BASH_REMATCH[1]}"
		fi

		if [[ $line =~ ^file_template:\ (.+) ]]; then
			global_file_template="${BASH_REMATCH[1]}"
		fi

		if [[ $line =~ ^source:\ (.+) ]]; then
			global_source="${BASH_REMATCH[1]}"
		fi

		continue
	fi

	# Note

	if [[ $line =~ ^source:\ (.+) ]]; then
		note_source="${BASH_REMATCH[1]}"
	fi
	
	if [[ $line =~ ^tags:\ (.+) ]]; then
		note_tags="${BASH_REMATCH[1]}"
	fi

	if [[ $line =~ ^north:\ (.+) ]]; then
		note_north="${BASH_REMATCH[1]}"
	fi

	if [[ $line =~ ^west:\ (.+) ]]; then
		note_west="${BASH_REMATCH[1]}"
	fi

	if [[ $line =~ ^east:\ (.+) ]]; then
		note_east="${BASH_REMATCH[1]}"
	fi

	if [[ $line =~ ^south:\ (.+) ]]; then
		note_south="${BASH_REMATCH[1]}"
	fi

	if [[ $line =~ ^###\ (.+) ]]; then
		note_title="${BASH_REMATCH[1]}"
		note_after_title=true
		continue
	fi

	if [[ $note_after_title == true ]]; then
		note_text+="$line\n"
	fi
done < $INPUT_FILE


