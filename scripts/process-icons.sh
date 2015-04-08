#This script will overlay version, git, and build configuration information over the icon for non-app store builds
#Inspiration: http://www.merowing.info/2013/03/overlaying-application-version-on-top-of-your-icon/

export PATH=$PATH:/usr/local/bin

#Don't run if imagemagick is not installed
if ! convert -version > /dev/null; then
	exit 0
fi

#Don't do this for App Store Releases
if [ "$CONFIGURATION" == "Release" ]; then
	exit 0
fi

function processIconSet() {

	#Get build number from info.plist
	build=`/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${INFOPLIST_FILE}"`

	#Get path to icons in app bundle
	icon_directory_path="${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
	echo "icon directory: "$icon_directory_path

	#Set the prefix of icon files so that we can find them in the the app bundle
	source_icon_set_prefix=$1
	echo "Source icon Prefix: "$source_icon_set_prefix

	#Fine the icons in the app bundle
	source_icons=`find "$icon_directory_path" -name "$source_icon_set_prefix*.png" -type f`
	echo "Source icons: "$source_icons

	#Looping through unescaped paths is fraught with peril
	#Tip found here: http://www.cyberciti.biz/tips/handling-filenames-with-spaces-in-bash.html
	SAVEIFS=$IFS
	IFS=$(echo -en "\n\b")
	echo "Set IFS for unescaped for loop paths"

	#Loop through icons
	for source_icon_path in ${source_icons}; do

		echo "Source icon path: $source_icon_path"

		#Image meta
		minimum_width=""
		width=`identify -format %w "$source_icon_path"`
		height=`identify -format %h "$source_icon_path"`

		#Overlay Height
		overlay_height=""
		overlay_color="#0008"

		#Set minimum width and overlay height based on icon size
		if [[ $source_icon_path == *"@3x"* ]]; then
			minimum_width=171
			overlay_height=60
		elif [[ $source_icon_path == *"@2x"* ]]; then
			minimum_width=114
			overlay_height=40
		else
			minimum_width=57
			overlay_height=20
		fi

		#Only process icons that show on home screens (> minimum_width)
		if [ $width -ge $minimum_width ]; then

			echo "Overlaying source Image "$source_icon_path

			#Overlay Image
			convert -background $overlay_color -fill white -gravity center -size ${width}x${overlay_height}\
			caption:"${CONFIGURATION}\n(${build})"\
			"${source_icon_path}" +swap -gravity south -composite "${source_icon_path}"

		else

			echo "Not overlaying source Image "$source_icon_path" because its width ("$width") is smaller than minimum size ("$minimum_width")"

		fi

	done

	IFS=$SAVEIFS
	echo "Reset IFS"

}

processIconSet "AppIcon"
