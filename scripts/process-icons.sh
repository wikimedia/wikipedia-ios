#This script will overlay version, git, and build configuration information over the icon for non-app store builds
#Inspiration: http://www.merowing.info/2013/03/overlaying-application-version-on-top-of-your-icon/

#Info to overlay on Icon
commit=`git rev-parse --short HEAD`
branch=`git rev-parse --abbrev-ref HEAD`
version=`agvtool what-marketing-version -terse1`
build=`/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${INFOPLIST_FILE}"`

#Where to save the files
target_path="${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/"

function processIconSet() {

	export PATH=$PATH:/usr/local/bin

	#Don't do this for App Store or Instore Release
	if [ "$CONFIGURATION" == "Release" ]; then
		exit 0
	fi

	#Make path to existing icons
	source_icon_set=$1
	source_icon_set_folder_name=$source_icon_set".appiconset"
	echo $source_icon_set_folder_name

	#Find existing icons
	source_icon_set_directory=`find . -name $source_icon_set_folder_name -type d`
	echo "Source icon directory: "$source_icon_set_directory

	#Make target base file name - same as asset collection name
	target_base_file_name=$source_icon_set
	echo "Target base file name: "$target_base_file_name

	#Loop through icons
	for source_icon_path in $(find $source_icon_set_directory -name "*.png" -type f); do

		#Image meta
		minimum_width=""
		retina_suffix=""
		width=""
		height=""
		icon_size_suffix=""
		width_suffix=""
		height_suffix=""

		overlay_height=""
		overlay_color="#0008"

		#Populate the image meta based on retina and size
		if [[ $source_icon_path == *"@3x"* ]]; then
			minimum_width=114
			retina_suffix="@3x"
			width=`identify -format %w "$source_icon_path"`
			height=`identify -format %h "$source_icon_path"`
			width_suffix=$width
			height_suffix=$height
			let "width_suffix/=3"
			let "height_suffix/=3"
			overlay_height=60
		elif [[ $source_icon_path == *"@2x"* ]]; then
			minimum_width=114
			retina_suffix="@2x"
			width=`identify -format %w "$source_icon_path"`
			height=`identify -format %h "$source_icon_path"`
			width_suffix=$width
			height_suffix=$height
			let "width_suffix/=2"
			let "height_suffix/=2"
			overlay_height=40
		else
			minimum_width=57
			retina_suffix=""
			width=`identify -format %w "$source_icon_path"`
			height=`identify -format %h "$source_icon_path"`
			width_suffix=$width
			height_suffix=$height
			overlay_height=20
		fi

		icon_size_suffix=$width_suffix"x"$height_suffix

		#Only process icons that show on home screens (larger ones)
		if [ $width -ge $minimum_width ]; then

			echo "Overlaying source Image "$source_icon_path

			#Assemble the final file path
			target_icon_file_name=$target_base_file_name$icon_size_suffix$retina_suffix".png"
			target_icon_path=$target_path$target_icon_file_name
			echo $source_icon_path" = "$target_icon_path

			#Overlay Image
			convert -background $overlay_color -fill white -gravity center -size ${width}x${overlay_height}\
			caption:"${CONFIGURATION}\n(${build})"\
			"${source_icon_path}" +swap -gravity south -composite "${target_icon_path}"

		else

			echo "Not overlaying source Image "$source_icon_path" because its width ("$width") is smaller than minimum size ("$minimum_width")"

		fi

	done

}
processIconSet "AppIcon"
