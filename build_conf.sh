build_source=from-x # CHANGE THIS to choose which Dockerfile to build from
rel_path=`dirname "${BASH_SOURCE}/"`/
repo_name=repo
img_name=image
tag=v
if [ ! -f $rel_path.version ];
then
	touch $rel_path.version
	echo 0>$rel_path.version
fi
version=$(<$rel_path.version)
img_full_name=$repo_name/$img_name:$tag$version

