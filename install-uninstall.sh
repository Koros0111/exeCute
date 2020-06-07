#! /bin/bash

: '
=== HOW TO RUN ===

For running this installer, in the application "Terminal" type:
"/pathToThisFolder/install-uninstall.sh"

For a list of programs installed like this type:
ls /etc/install-uninstall


=== PURPOSE ===

This installer is mostly for trying out the software
If you end liking it, ask someone how to package it

If your system includes the app "pacman", you can get packages at:
https://gitlab.com/es20490446e/express-repository/-/wikis/home


=== LEGALESE ===

Installer by Alberto Salvia Novella (es20490446e.wordpress.com)
Under the latest GNU Affero License
https://gitlab.com/es20490446e/install-uninstall.sh
'


here="$(realpath "$(dirname "${0}")")"
program="$(cd ${here}; echo ${PWD##*/})"
in="${here}/root"

etc="etc/install-uninstall"
lists="${etc}/${program}"
fileList="${lists}/files"
dirList="${lists}/dirs"

test="false"
out=""


mainFuntion () {
	if [ ! -d "${out}/${lists}" ]; then
		checkDependencies
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
	if [ -z "${out}" ] && [ "$(id -u)" -ne 0 ]; then
		sudo "${0}"
		exit ${?}
	fi
}


checkDependencies () {
	list="${here}/info/dependencies.txt"

	if [ -f "${list}" ]; then
		readarray -t lines < <(cat "${list}")
		missing=()

		for line in "${lines[@]}"; do
			name=$(echo "${line}" | cut --delimiter='"' --fields=2)
			path=$(echo "${line}" | cut --delimiter='"' --fields=4)
			web=$(echo "${line}" | cut --delimiter='"' --fields=6)

			if [ ! -z "${web}" ]; then
				web="(${web})"
			fi

			if ! $(ls $path &> /dev/null); then
				missing+=("${name}  ${web}")
			fi
		done

		if [ ! -z "${missing}" ]; then
			echo "Missing required software:" >&2
			echo >&2
			printf '%s\n' "${missing[@]}" >&2
			echo >&2
			echo "Get those installed first"
			echo "and run this installer again"
			exit 1
		fi
	fi
}


cleanUp () {
	if [ ! -z "${out}" ] && [ -d "${out}" ]; then
		rm --recursive "/${out}"
	fi
}


createLists () {
	if [ ! -d "${lists}" ]; then
		mkdir --parents "${out}/${lists}"
	fi

	echo "${fileList}" > "${out}/${fileList}"
	echo "${dirList}" >> "${out}/${fileList}"
	echo "${etc}" > "${out}/${dirList}"
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


fileMime () {
	file="${1}"

	file --brief --mime "${file}" |
	cut --delimiter=';' --fields=1
}


fileParents () {
	file="${1}"

	echo ${file} |
	rev |
	cut --delimiter='/' --fields=2- |
	rev
}


installFile () {
	file="${1}"

	if [ "$(fileMime "${in}/${file}")" == "inode/symlink" ]; then
		installSymlink "${file}"
	else
		install -D "${in}/${file}" "${out}/${file}"
	fi
}


installSymlink () {
	symlink="${1}"
	target="$(realpath "${in}/${symlink}")"

	makeParents "${symlink}"
	ln --symbolic "${target}" "${out}/${symlink}"
}


installs () {
	readarray -t files < <(toInstall)
	createLists

	for file in "${files[@]}"; do
		installFile "${file}"
		echo "${file}" >> "${out}/${fileList}"
	done

	dirsInFolder "${in}" >> "${out}/${dirList}"
	echo "installed"
}


makeParents () {
	file="${1}"
	parents="$(fileParents "${file}")"
	mkdir --parents "${out}/${parents}"
}


prepareEnvironment () {
	set -e
	updateInstaller
	checkPermissions
	trap "" INT QUIT TERM EXIT
	cleanUp
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
		if [ -d "${out}/${dir}" ] && [ -z "$(find "${out}/${dir}" -not -type d)" ]; then
			rm --recursive --force "${out}/${dir}"
		fi
	done

	echo "uninstalled"
}


updateInstaller () {
	if [ "${test}" == "false" ]; then
		remote="$(curl --silent "https://gitlab.com/es20490446e/install-uninstall.sh/-/raw/master/install-uninstall.sh")"
		local="$(cat "${0}")"

		if [ ! -z "${remote}" ] && [ "${remote}" != "${local}" ]; then
			echo "${remote}" > "${0}"
			sudo "${0}"
			exit ${?}
		fi
	fi
}


prepareEnvironment "${@}"
mainFuntion
