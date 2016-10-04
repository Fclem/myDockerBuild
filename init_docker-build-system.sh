#!/bin/bash
# TODO create the from-x folder, and empty Dockerfile, create build_conf.sh template, write build_conf.sh from template
default_tag_prefix=v
valid_registry="{\"detail\": \"Object not found\"}"
no_repo="{\"count\": 0, \"next\": null, \"previous\": null, \"results\": []}"
no_image="{\"detail\": \"Object not found\"}"
no_tag="{\"detail\": \"Object not found\"}"
docker_hub_url=https://registry.hub.docker.com/v2/repositories/

# term colors
END_C="\e[0m"
RED="\e[91m"
L_CYAN="\e[96m"
L_YELL="\e[93m"
GREEN="\e[32m"
BOLD="\e[1m"

function check_object_exists { # 1: get_url, 2: error_content, 3: object_name, 4: docker_registry_url, 5: custom_error_msg
	res=`curl -s $1`
	# echo "get_url: "$1
	# echo "error_content: "$2
	# echo "object_name: "$3
	# echo "docker_registry_url: "$4
	if [[ -z "$3" ]]; then
		echo -e $RED"object name is empty"$END_C
		exit
	fi
	if [[ -z "$res" ]]; then
		error_msg=$RED"empty response"$END_C" from"
		if [[ -n "$5" ]]; then
			error_msg=$5
		fi
		echo -e $error_msg $BOLD$1$END_C
		exit
	fi
	 if [ "$2" = "$res" ]; then
		echo -e "object $BOLD$3$END_C "$RED"not found"$END_C" at $BOLD$4$END_C"
		exit
	fi
}

function check_registry_is_valid { # 1: get_url, 2: match_content, 3: custom_error_msg
	check_object_exists "$1" "" "registry" "$1" "$3"
	 if [ "$2" != "$res" ]; then
		echo -e $RED"no valid docker registry found$END_C at target url $BOLD$1$END_C"
		exit
	fi
}


# source registry url
echo -ne "enter a valid v2 docker registry url (leave blank for default \"$BOLD$docker_hub_url$END_C\"): "
read repository_url
if [[ -z "$repository_url" ]]; then
	repository_url=$docker_hub_url
fi
get_url="$repository_url"
check_registry_is_valid "$get_url" "$valid_registry" $RED"Unable to fetch from url"$END_C

# source repository name
echo -n "enter repo name: "
read repo
get_url="$repository_url$repo/"
check_object_exists "$get_url" "$no_repo" "$repo" "$repository_url"

# source image name
echo -n "enter image name: "
read image
get_url="$repository_url$repo/$image/"
check_object_exists "$get_url" "$no_image" "$image" "$repository_url"

# source tag name
echo -ne "enter tag name (leave blank for default \""$BOLD"latest"$END_C"\"): "
read tag
if [[ -z "$tag" ]]; then
	tag=latest
fi
get_url="$repository_url$repo/$image/tags/$tag/"
check_object_exists "$get_url" "$no_tag" "$image" "$repository_url"

echo -n "enter your email address: "
read email
full_img_name=$repo/$image:$tag
dir_name=from-$repo"_"$image:$tag
mkdir $dir_name

echo "FROM $repo/$image:$tag
MAINTAINER $email
">$dir_name/Dockerfile && echo -e $L_CYAN"Created$END_C $dir_name/Dockerfile"

# target registry url
echo -ne "enter repository url (leave blank for default \"$BOLD$docker_hub_url$END_C\"): "
read repository_url
if [[ -z "$repository_url" ]]; then
	repository_url=$docker_hub_url
fi
get_url="$repository_url"
check_object_exists "$get_url" "$no_registry" "docker registry" "$repository_url" $RED"no valid docker repository"$END_C" at"

# target repository name
echo -n "enter YOUR repo name :"
read my_repo

# target image name
echo -n "enter YOUR image name :"
read my_image

echo -ne "enter a tag prefix (leave blank for default \"$BOLD$default_tag_prefix$END_C\", tag will be automaticaly suffixed with a version number): "
read my_tag
if [[ -z "$my_tag" ]]; then
	my_tag=default_tag_prefix
fi

echo "### AUTO GENERATED ###
build_source=$dir_name # CHANGE THIS to choose which Dockerfile to build from
repo_name=$my_repo
img_name=$my_image
tag=v # this is the image tag prefix, which will be sufixed by an incremented version number
### END GENERATED ###">build_conf.sh && echo -e $L_CYAN"Created$END_C build_conf.sh"

echo "docker pull $full_img_name"
docker pull $full_img_name

chmod u+x build.sh run.sh
