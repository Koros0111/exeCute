#! /bin/bash
#  Installer by Alberto Salvia Novella (es20490446e.wordpress.com)
#  Under the latest GNU Affero License
#
#  For RUNNING this program, in the application "Terminal" type:
#  "/pathToThisFolder/install-uninstall.sh"


here="$(dirname "${0}")"
program="$(cd ${here}; echo ${PWD##*/})"
in="${here}/root"
out="${here}/out"

etc="etc/install-uninstall"
lists="${etc}/${program}"
fileList="${lists}/files"
dirList="${lists}/dirs"


mainFuntion () {
	if [ ! -d "${out}/${lists}" ]; then
		checkRequired
		builds
		installs
	else
		uninstalls
	fi
}


builds () {
	if [ ! -d "${in}" ] && [ -f "${here}/build.sh" ]; then
		bash "${here}/build.sh"
	fi

	if [ ! -d "${in}" ] && [ -f "${here}/build.sh" ]; then
		echo "build.sh hasn't built anything on: ${in}" >&2
		exit 1
	fi
}


checkPermissions () {
	this="${0}"
	user=$(id -u)

	if [ ${user} -ne 0 ]; then
		sudo "${this}"
		exit ${?}
	fi
}


checkRequired () {
	list="${here}/info/required.txt"

	if [ -f "${list}" ]; then
		readarray -t required < <(cat "${list}")
		missing=""

		for requirement in "${required[@]}"; do
			if [ ! -f "${requirement}" ]; then
				missing="$(echo -e "${missing}\n${requirement}")"
			fi
		done

		if [ "${missing}" != "" ]; then
			echo "Missing requirements:" >&2
			echo "${missing}" >&2
			echo
			echo "Get those installed first"
			echo "and run this installer again"
			exit 1
		fi
	fi
}


createLists () {
	if [ ! -d "${lists}" ]; then
		mkdir --parents "${out}/${lists}"
	fi

	echo "${fileList}" > "${out}/${fileList}"
	echo "${dirList}" >> "${out}/${fileList}"

	echo "etc" > "${out}/${dirList}"
	echo "${etc}" >> "${out}/${dirList}"
	echo "${lists}" >> "${out}/${dirList}"
}


dirsInFolder () {
	folder="${1}"

	dirs=$(
		cd "${folder}"
		find . -type d |
		cut --delimiter='/' --fields=2-
	)

	echo "${dirs}" | tail -n +2
}


installs () {
	readarray -t files < <(toInstall)
	createLists

	for file in "${files[@]}"; do
		install -D "${in}/${file}" "${out}/${file}"
		echo "${file}" >> "${out}/${fileList}"
	done

	dirsInFolder "${in}" >> "${out}/${dirList}"
	echo "installed"
}


toInstall () {
	toInstall=$(
		cd "${here}/root"
		find . -not -type d |
		cut --delimiter='/' --fields=2-
	)

	echo "${toInstall}"
}


uninstalls () {
	readarray -t files < <(cat "${out}/${fileList}")
	readarray -t dirss < <(cat "${out}/${dirList}")

	for file in "${files[@]}"; do
		rm "${out}/${file}"
	done

	for dir in "${dirss[@]}"; do
		if [ -d "${out}/${dir}" ] && [ "$(find "${out}/${dir}" -not -type d)" == "" ]; then
			rm --recursive --force "${out}/${dir}"
		fi
	done

	echo "uninstalled"
}


set -e
checkPermissions
trap "" INT QUIT TERM EXIT
mainFuntion
