node {
	deleteDir()

	dir('ci') {
		checkout scm
	}

	dir('albert') {
		checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[url: 'https://github.com/albertlauncher/albert.git']]])

		// Derive version number from latest tag + jenkins build number
		sh "echo `git describe --abbrev=0 --tags | sed s/^v//g`-${env.BUILD_NUMBER} > ../PACKAGE_VERSION"
	}

	stash 'ci'
	stash 'albert'
	stash 'PACKAGE_VERSION'

	def debianVersions = ["sid", "unstable"]

	stage('install dependencies') {
		def jobs = [:]

		// Create dockerfile based of template
		for (version in debianVersions) {
			def v = version
			def buildImageClosure = { node {
				unstash 'ci'
				dir('ci') {
					sh "cat Dockerfile.tpl | sed s/DEBIAN_VERSION/${v}/g > Dockerfile.${v}"
					// Use docker cache to minimize build time
					catchError {
						docker.build("build-albert:${v}", "-f Dockerfile.${v} .")
					}
				}
			}}

			jobs[v] = buildImageClosure
		}
		parallel jobs
	}

	stage('make') {
		def jobs = [:]
		for (v in debianVersions) {
			def version = v
			def makeClosure = { node {
				unstash 'albert'

				sh "cp -a albert albert-${version}"
				sh "mkdir -p albert-${version}/build"

				def app = docker.image("build-albert:${version}")
				dir("albert-${version}/build") {
					app.inside {
						sh "cmake .. -DCMAKE_BUILD_TYPE=Release"
						sh "make"

						// Install albert into custom directory
						sh "make DESTDIR=albertbuild-${version} install"
					}
					stash "albertbuild-${version}"
				}
			}}

			jobs[version] = makeClosure
		}
		parallel jobs
  }

	stage('package') {
		def jobs = [:]

		for (v in debianVersions) {
			def version = v
			def job = { node {
				def app = docker.image("debian:${version}")
				def buildDirectory = "albertbuild-${version}"

				unstash buildDirectory
				unstash 'ci'
				unstash 'PACKAGE_VERSION'

				app.inside {
					// Prepare directory for packaging
					sh "mkdir -p ${buildDirectory}/DEBIAN"
					// Create DEBIAN/control file With current VERSION
					sh "cat ci/DEBIAN-control | sed s/PACKAGE_VERSION/`cat PACKAGE_VERSION`/g > ${buildDirectory}/DEBIAN/control"
					// Fix permissions, the suid bit has been set for the complete directory (can't explain why every file in the workspace has it but it's a very bad idea to keep it while packaging)
					sh "chmod -R -s ${buildDirectory}"
					// Pack albert-VERSION-BUILD_NUMBER.deb file
					sh "dpkg-deb -b ${buildDirectory} albert-`cat PACKAGE_VERSION`-${version}.deb"
				}

				archiveArtifacts '*.deb'

			}}
			jobs[version] = job
		}
		parallel jobs
	}
}
