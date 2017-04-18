node {
	deleteDir()

	stage('checkout') {
		dir('ci') {
			checkout scm
		}

		dir('albert') {
			checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[url: 'https://github.com/albertlauncher/albert.git']]])
		}
	}

	def app
	stage('install dependencies') {
		dir('ci') {
			// Use docker cache to minimize build time
			app = docker.build('albert-launcher')
		}
	}

	stage('make') {
		sh "mkdir -p albert/build"

		dir('albert/build') {
			app.inside {
				sh "cmake .. -DCMAKE_BUILD_TYPE=Release"
				sh "make"
			}
		}
  }

	stage('package') {
		dir('albert/build') {
			app.inside {
				// Install albert into custom directory
				sh "make DESTDIR=/tmp/albertbuild install"

				// Derive version number from latest tag + jenkins build number
				sh "echo `git describe --abbrev=0 --tags | sed s/^v//g`-${env.BUILD_NUMBER} > VERSION"

				// Prepare directory for packaging
				sh "mkdir -p /tmp/albertbuild/DEBIAN"
				// Create DEBIAN/control file With current VERSION
				sh "VERSION=`cat VERSION` envsubst < ../../ci/DEBIAN-control > /tmp/albertbuild/DEBIAN/control"

				// Pack albert-VERSION-BUILD_NUMBER.deb file
				sh "dpkg-deb -b /tmp/albertbuild albert-`cat VERSION`.deb"
			}
			archiveArtifacts '*.deb'
		}
	}
}
