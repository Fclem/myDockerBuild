#!/bin/bash
###
#  CONF & CONST
###
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
function check_object_exists { # 1: get_url, 2: error_content, 3: object_name, 4: docker_registry_url, 5: custom_error_msg
	# echo "curl -s "$1
	res=`curl -s $1`
	# echo $res
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
	if [ "$2" == "$res" ]; then
		echo -e "object $BOLD$3$END_C "$RED"not found"$END_C" at $BOLD$4$END_C"
		exit
	fi
	#echo "must be \""$2"\"!=\""$res"\""
}

function check_registry_is_valid { # 1: get_url, 2: match_content, 3: custom_error_msg
	check_object_exists "$1" "" "registry" "$1" "$3"
	 if [ "$2" != "$res" ]; then
		echo -e $RED"no valid docker registry found$END_C at target url $BOLD$1$END_C"
		exit
	fi
}

#################
#  SOURCE INFO  #
#################
echo -e $L_CYAN"### Docker SOURCE configuration : ###"$END_C

# source registry url
echo -ne "enter a valid SOURCE v2 docker registry url (leave blank for default \"$BOLD$docker_hub_url$END_C\"): "
read source_repository_url
if [[ -z "$source_repository_url" ]]; then
	source_repository_url=$docker_hub_url
fi
get_url="$source_repository_url"
check_registry_is_valid "$get_url" "$valid_registry" $RED"Unable to fetch from url"$END_C

# source repository name
echo -n "enter SOURCE repository name: "
read repo
get_url="$source_repository_url$repo/"
check_object_exists "$get_url" "$no_repo" "$repo" "$source_repository_url"

# source image name
echo -n "enter SOURCE image name: "
read image
get_url="$source_repository_url$repo/$image/"
check_object_exists "$get_url" "$no_image" "$image" "$source_repository_url$repo/"

# source tag name
echo -ne "enter SOURCE tag name (leave blank for default \""$BOLD"latest"$END_C"\"): "
read tag
if [[ -z "$tag" ]]; then
	tag=latest
fi
get_url="$source_repository_url$repo/$image/tags/$tag/"
check_object_exists "$get_url" "$no_tag" "$tag" "$source_repository_url$repo/$image/tags/"

###################
#  PERSONAL INFO  #
###################

# maintainer email address
echo -n "enter your email address: "
read email

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
echo -ne "enter a valid TARGET v2 docker registry url (leave blank for default \"$BOLD$docker_hub_url$END_C\"): "
read target_repository_url
if [[ -z "$target_repository_url" ]]; then
	target_repository_url=$docker_hub_url
fi
get_url="$target_repository_url"
check_registry_is_valid "$get_url" "$valid_registry" $RED"Unable to fetch from url"$END_C
# check_object_exists "$get_url" "$no_registry" "docker registry" "$target_repository_url" $RED"no valid docker repository"$END_C" at"

# target repository name
echo -n "enter TARGET repository name :"
read my_repo

# target image name
echo -n "enter TARGET image name :"
read my_image

# target tag prefix
echo -ne "enter a TARGET tag prefix (leave blank for default \"$BOLD$default_tag_prefix$END_C\", tag will be automaticaly suffixed with a version number): "
read my_tag
if [[ -z "$my_tag" ]]; then
	my_tag=default_tag_prefix
fi

# generating build_conf.sg that is used by all shell scripts, containing target image's repo name, name, and tag, and build source folder
echo "### AUTO GENERATED ###
build_source=$dir_name # CHANGE THIS to choose which Dockerfile to build from
repo_name=$my_repo
img_name=$my_image
tag=v # this is the image tag prefix, which will be sufixed by an incremented version number
### END GENERATED ###">build_conf.sh && echo -e $L_CYAN"Created$END_C build_conf.sh"

############
#  DOCKER  #
############
echo "docker pull $full_img_name"
docker pull $full_img_name

######################
#  FILE PERMISSIONS  #
######################
chmod u+x build.sh run.sh

echo "DONE !"
