#!/bin/bash
##################
#  CONF & CONST  #
##################
default_tag_prefix=v
valid_registry="{\"detail\": \"Object not found\"}"
no_repo="{\"count\": 0, \"next\": null, \"previous\": null, \"results\": []}"
no_image="{\"detail\": \"Object not found\"}"
no_tag="{\"detail\": \"Not found\"}"
docker_hub_url=https://registry.hub.docker.com/v2/repositories/
# term colors
END_C="\e[0m"
RED="\e[91m"
L_CYAN="\e[96m"
L_YELL="\e[93m"
GREEN="\e[32m"
BOLD="\e[1m"

#########################
#  UTILITIES FUNCTIONS  #
#########################
function check_object_exists() { # 1: get_url, 2: error_content, 3: object_name, 4: docker_registry_url, 5: custom_error_msg
	res=`curl -s $1`
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
	if [ "$2" == "$res" ]; then
		echo -e "object $BOLD$3$END_C "$RED"not found"$END_C" at $BOLD$4$END_C"
		exit
	fi
}

function check_registry_is_valid() { # 1: get_url, 2: match_content, 3: custom_error_msg
	check_object_exists "$1" "" "registry" "$1" "$3"
	if [ "$2" != "$res" ]; then
		echo -e $RED"no valid docker registry found$END_C at target url $BOLD$1$END_C"
		exit
	fi
}

function list_img_from_repo() { # 1: repository_json_input
	echo $1 | python -c "import json,sys;obj=json.load(sys.stdin);
	out='';
	for each in obj['results']: out+=each['name']+', ';
	print(out[:-2]);"
}

echo -e $GREEN"Configuration script for this new Docker build system, please fill in some parameters :"$END_C

#################
#  SOURCE INFO  #
#################
echo -e $L_CYAN"### Docker SOURCE configuration : ###"$END_C

# source registry url
echo -ne "enter a valid SOURCE v2 docker registry url (leave blank for default \"$BOLD$docker_hub_url$END_C\"): "$BOLD
read source_repository_url
echo -ne $END_C
if [[ -z "$source_repository_url" ]]; then
	source_repository_url=$docker_hub_url
fi
get_url="$source_repository_url"
check_registry_is_valid "$get_url" "$valid_registry" $RED"Unable to fetch from url"$END_C

# source repository name
echo -ne "enter SOURCE repository name: "$BOLD
read repo
echo -ne $END_C
get_url="$source_repository_url$repo/"
check_object_exists "$get_url" "$no_repo" "$repo" "$source_repository_url"

# listing existing images in this repo:
echo -n "available images in $repo: "
list_images_from_repo $res

# source image name
echo -ne "enter SOURCE image name: "$BOLD
read image
echo -ne $END_C
get_url="$source_repository_url$repo/$image/"
check_object_exists "$get_url" "$no_image" "$image" "$source_repository_url$repo/"

# source tag name
echo -ne "enter SOURCE tag name (leave blank for default \""$BOLD"latest"$END_C"\"): "$BOLD
read tag
echo -ne $END_C
if [[ -z "$tag" ]]; then
	tag=latest
fi
get_url="$source_repository_url$repo/$image/tags/$tag/"
check_object_exists "$get_url" "$no_tag" "$tag" "$source_repository_url$repo/$image/tags/"

###################
#  PERSONAL INFO  #
###################

# maintainer email address
echo -ne "enter your email address: "$BOLD
read email
echo -ne $END_C

# create the Dockerfile directory
full_img_name=$repo/$image:$tag
dir_name=from-$repo"_"$image:$tag
mkdir $dir_name
# create the Dockerfile
echo "FROM $repo/$image:$tag
MAINTAINER $email
">$dir_name/Dockerfile && echo -e $L_CYAN"Created$END_C $dir_name/Dockerfile"

#################
#  TARGET INFO  #
#################
echo -e $L_CYAN"### Docker TARGET configuration : ###"$END_C

# target registry url
echo -ne "enter a valid TARGET v2 docker registry url (leave blank for default \"$BOLD$docker_hub_url$END_C\"): "$BOLD
read target_repository_url
echo -ne $END_C
if [[ -z "$target_repository_url" ]]; then
	target_repository_url=$docker_hub_url
fi
get_url="$target_repository_url"
check_registry_is_valid "$get_url" "$valid_registry" $RED"Unable to fetch from url"$END_C

# target repository name
echo -ne "enter TARGET repository name: "$BOLD
read target_repo
echo -ne $END_C
get_url="$target_repository_url$target_repo/"
check_object_exists "$get_url" "$no_repo" "$target_repo" "$target_repository_url"

# target image name
echo -ne "enter TARGET image name: "$BOLD
read target_image
echo -ne $END_C
# do not check, since this could be a new image
# listing existing images in this repo:
echo -n "available images in $repo: "
list_images_from_repo $res

# target tag prefix
echo -ne "enter TARGET tag prefix (leave blank for default \"$BOLD$default_tag_prefix$END_C\", tag will be automaticaly suffixed with a version number): "$BOLD
read target_tag
echo -ne $END_C
if [[ -z "$target_tag" ]]; then
	target_tag=default_tag_prefix
fi
# no check

# generating build_conf.sg that is used by all shell scripts, containing target image's repo name, name, and tag, and build source folder
echo "### AUTO GENERATED ###
build_source=$dir_name # CHANGE THIS to choose which Dockerfile to build from
repo_name=$target_repo
img_name=$target_image
tag=$target_tag # this is the image tag prefix, which will be sufixed by an incremented version number
### END GENERATED ###">build_conf.sh && echo -e $L_CYAN"Created$END_C build_conf.sh"

############
#  DOCKER  #
############
echo -e $L_CYAN"Pulling $full_img_name from registry"$END_C
docker pull $full_img_name

######################
#  FILE PERMISSIONS  #
######################
# chmod u+x build.sh run.sh
rm init_docker-build-system.sh # delete self

echo -e $GREEN"DONE !"$END_C
