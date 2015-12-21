  #This script will overlay information over the app icon
  #Inspiration: http://www.merowing.info/2013/03/overlaying-application-version-on-top-of-your-icon/

  export PATH=$PATH:/usr/local/bin

  which -s gs
  if [[ $? != 0 ]]; then
    echo "Please install ghostscript to create app icon overlays."
    exit 0
  fi

  which -s convert
  if [[ $? != 0 ]]; then
    echo "Please install imagemagick to create app icon overlays."
    exit 0
  fi

  which -s identify
  if [[ $? != 0 ]]; then
    echo "Please install imagemagick to create app icon overlays."
    exit 0
  fi

  set -e

  function processIconSet() {

    #Get build number from info.plist
    build=`/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${INFOPLIST_FILE}"`
    icon_caption="${CONFIGURATION}\n(${build})"
    last_icon_caption_file="${CONFIGURATION_BUILD_DIR}/icon_caption"

    if [[ -f "${last_icon_caption_file}" && `cat "${last_icon_caption_file}"` == "${icon_caption}" ]]; then
      echo "Already overlaid ${icon_caption} on icons, skipping."
      exit 0
    fi

    #Find existing icons
    source_icon_set_prefix=$1
    source_icon_set_folder_name=$source_icon_set_prefix".appiconset"
    source_icon_set_directory=`find . -name $source_icon_set_folder_name -type d`
    echo "Source icon directory: "$source_icon_set_directory

    #Find target icons
    target_icon_set_prefix=$2
    target_icon_set_folder_name=$target_icon_set_prefix".appiconset"
    target_icon_set_directory=`find . -name $target_icon_set_folder_name -type d`
    echo "Target icon directory: "$target_icon_set_directory

    #Fine the icons in the app bundle
    source_icons=`find "$source_icon_set_directory" -name "*.png" -type f`
    echo "Source icons: "$source_icons

    #Looping through unescaped paths is fraught with peril
    #Tip found here: http://www.cyberciti.biz/tips/handling-filenames-with-spaces-in-bash.html
    SAVEIFS=$IFS
    IFS=$(echo -en "\n\b")
    echo "Set IFS for unescaped for loop paths"

    #Loop through icons
    for source_icon_path in ${source_icons}; do

      target_icon_path="${target_icon_set_directory}/${source_icon_path##*/}"
      echo "Source icon path: $source_icon_path"
      echo "Target icon path: $target_icon_path"

      if ! convert -version > /dev/null; then
        #Don't run if imagemagick is not installed
        cp "${source_icon_path}" "${target_icon_path}"

      elif [ "$CONFIGURATION" == "Release" ]; then
        #Don't do this for App Store Releases
        cp "${source_icon_path}" "${target_icon_path}"
        echo "Not overlaying source Image for Release build"

      else

        #Image meta
        width=`identify -format %w "$source_icon_path"`
        height=`identify -format %h "$source_icon_path"`
        # echo "Width: "$width
        # echo "Height: "$height

        #Overlay Size
        overlay_height=$height
        overlay_width=$width
        let "overlay_height/=4"
        let "overlay_width*=3"

        # echo "O Width: "$overlay_width
        # echo "O Height: "$overlay_height

        #Overlay Color
        overlay_color="#0008"

        #Only process larger icons
        minimum_width=57

        if [[ $width -ge $minimum_width ]]; then

          echo "Overlaying source image "$source_icon_path

          #Overlay Image
          convert -background $overlay_color -fill white -gravity center -size ${overlay_width}x${overlay_height}\
          caption:"${icon_caption}"\
          "${source_icon_path}" +swap -gravity south -composite "${target_icon_path}"

        else
          #For everything else, just copy it over
          cp "${source_icon_path}" "${target_icon_path}"
          echo "Not overlaying source Image "$source_icon_path" because its width ("$width") is smaller than minimum size ("$minimum_width")"
        fi

      fi

    done

    #Copy JSON
    source_json_path=`find "$source_icon_set_directory" -name "*.json" -type f`
    target_json_path="${target_icon_set_directory}/${source_json_path##*/}"

    cp "${source_json_path}" "${target_json_path}"
    echo "Copying JSON from "$source_json_path" to "$target_json_path

    IFS=$SAVEIFS
    echo "Reset IFS"

    echo "Writing ${icon_caption} to last-processed icon caption file: ${last_icon_caption_file}"
    echo "${icon_caption}" > "${last_icon_caption_file}"
  }

  processIconSet "AppIconSource" "AppIcon"
