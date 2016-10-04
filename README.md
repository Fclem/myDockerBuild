# myDockerBuild
A custom and personal docker build system

## Usage

1. Copy paste this line in a terminal, **within** the desired **empty** target directory :
  * with **bash**:
  ```console
  $ git clone git@github.com:Fclem/myDockerBuild.git . && rm -fr .git && \
  ./init_docker-build-system.sh
  ```
  * with **fish**:
  ```console
  $ git clone git@github.com:Fclem/myDockerBuild.git . ; and rm -fr .git; and \
  ./init_docker-build-system.sh
  ```
2. Proceed to edit `from-*/Dockerfile` to include any desired changes
3. Finaly build the new docker image
  
  ```console
  $ ./build.sh
  ```

4. Optionaly push your image to a preconfigured docker registry
  
  ```console
  $ docker push repo/image
  ```

