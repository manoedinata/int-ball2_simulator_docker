# Int‑Ball2 Simulator Docker Environment 🚀

<p style="display: inline">
  <img src="https://img.shields.io/badge/-Docker-1488C6.svg?logo=docker&style=flat">
  <img src="https://img.shields.io/badge/ROS-darkblue?logo=ros">
</p>

*[日本語版 / Japanese version](README.jp.md)*

 **int‑ball2_simulator_docker** packages the [JAXA Int‑Ball2 simulator](https://github.com/jaxa/int-ball2_simulator) and your user program (control node) as Docker images, and provides an environment for running them together with Docker Compose.  
It lets you easily simulate the behavior of a free‑flying robot in a microgravity environment. 💫

---

## Overview ✨

- **Purpose**: Launch the Int‑Ball2 simulator + your user program with simple commands  
- **Verified environment**: Windows 11 + WSL2 (Ubuntu 24.04)  
- **Key technologies**: Docker‑outside‑of‑Docker (DooD), ROS, X11 / WSLg

---

## Architecture Overview 🖼️

  ```mermaid
  graph TB
      subgraph HostEnvironment
          dockerService["Docker Service"]
          userProgram["User Program"]
        
          subgraph SimulatorContainer
              gse["GSE"]
              rvizGazebo["RViz+Gazebo"]
          end
        
          subgraph UserProgramContainer
              cmdsh["cmd.sh"]
          end
      end
    
      dockerService -- "Run" --> SimulatorContainer
      gse -- "Docker Run" --> UserProgramContainer
      gse <-- "CMD/TLM" --> rvizGazebo
      cmdsh -- "Run" --> userProgram
      userProgram -- "Control" --> rvizGazebo
  ```

1. The **simulator container**, the **user program container**, and the **user program** are all placed on the host environment.
2. The GSE inside the **simulator container** operates the host's Docker Engine to launch the **user program container**.  
3. `/var/run/docker.sock` is shared so that the **user program container** can be created and managed.
4. The **user program container** launches the user program located on the host environment, which controls the Int‑Ball2 model in the **simulator container**.
5. The GUI is displayed on the host's screen via X11 / WSLg.  

---

## Prerequisites 📝

- **Docker** and **Docker Compose** installed on the host environment  
- A [**Qt account**](https://login.qt.io/login) (email address & password)  
- An **X11/WSLg** environment for displaying the simulator GUI

> **Note**: Registering a Qt license is free.  

---

## Setup and Execution Steps 💻

### 1. Clone this repository

```bash
cd ~ # any directory
git clone https://github.com/jaxa/int-ball2_simulator_docker.git
cd int-ball2_simulator_docker
```

### 2. Create the shared file directory

```bash
mkdir -p shared_data_sim
```

### 3. Place your user program

Put the ROS package of your user program under `int-ball2_simulator_docker/ib2_user_ws/src/user/`.

### 4. Build the simulator Docker image
Before running the command, replace `your.email@example.com` and `your_password` with your own Qt account credentials.

```bash
docker build --build-arg HOST_USER_PATH="$(pwd)" --build-arg QT_EMAIL=your.email@example.com --build-arg QT_PASSWORD=your_password -t ib2_simulator:latest .
```

**(Optional)**

You can also use a pre-built image. (However, as-is it requires the user name "nvidia" and the directory structure "~/int-ball2_simulator_docker".)

```bash
docker pull ghcr.io/jaxa/ib2_simulator:latest
docker tag ghcr.io/jaxa/ib2_simulator:latest ib2_simulator:latest # to match the rest of this guide
```

> **Caution**: The first build can take more than 60 minutes.

### 5. Build the user program
Build the user program located on the host environment using the ROS system of the simulator container.

```bash
cd ~/int-ball2_simulator_docker # any directory
docker run --rm \
  -v "$(pwd)/ib2_user_ws:$(pwd)/ib2_user_ws" \
  ib2_simulator:latest \
  bash -c "source /opt/ros/melodic/setup.bash && \
           source /home/nvidia/IB2/Int-Ball2_platform_simulator/devel/setup.bash && \
           cd $(pwd)/ib2_user_ws && catkin_make"
```

### 6. Build the platform_works image
Build the user program image.

```bash
cd ~ # any directory
git clone https://github.com/jaxa/int-ball2_platform_works.git platform_works
cd platform_works/platform_docker/template
docker build -t ib2_user:0.1 .
```

### 7. Start the simulator container with Docker Compose

```bash
# Start the simulator & user program in the background
cd int-ball2_simulator_docker
PWD=$(pwd) docker compose up -d

# To enter the simulator container
docker exec -it ib2_simulator bash
```

---

## Running the Simulator 🕹️

### Terminal 1: Start the GSE

Continuing from step 7 above:

```bash
# Inside the ib2_simulator container
source /opt/ros/melodic/setup.bash
source /home/nvidia/IB2/Int-Ball2_platform_gse/devel/setup.bash
roslaunch platform_gui bringup.launch
```

### Terminal 2: Start the simulator
Run the following in another terminal:

```bash
docker exec -it ib2_simulator bash

# Inside the container
source /opt/ros/melodic/setup.bash
source /home/nvidia/IB2/Int-Ball2_platform_simulator/devel/setup.bash
rosrun platform_sim_tools simulator_bringup.sh
```

---

## How to Update the User Program 🔄

After changing your program, you need to rebuild it.

```bash
docker run --rm \
  -v "$(pwd)/ib2_user_ws:$(pwd)/ib2_user_ws" \
  ib2_simulator:latest \
  bash -c "source /opt/ros/melodic/setup.bash && \
           source /home/nvidia/IB2/Int-Ball2_platform_simulator/devel/setup.bash && \
           cd $(pwd)/ib2_user_ws && catkin_make"
PWD=$(pwd) docker compose restart        # if necessary
```

---

## Platform-Specific Settings ⚙️

### Windows + WSL2

- **WSLg** is used for the GUI display  
- The environment variables in `docker-compose.yml` are set as follows by default  
  ```yaml
  environment:
    - DISPLAY
    # - NVIDIA_VISIBLE_DEVICES=all
    # - NVIDIA_DRIVER_CAPABILITIES=all
    - LIBGL_ALWAYS_INDIRECT=0
    - QT_X11_NO_MITSHM=1
    - MESA_GL_VERSION_OVERRIDE=3.3
  ```
- If you want to use an NVIDIA GPU, uncomment `runtime: nvidia`, `NVIDIA_VISIBLE_DEVICES=all`, and `NVIDIA_DRIVER_CAPABILITIES=all`.

### Linux

- In the terminal where you start the ib2_simulator container, run the following beforehand to allow access to X11.
  ```bash
  xhost +local:docker
  ```

---

## Troubleshooting 🛠️

| Symptom | Common cause | Solution |
| ------- | ------------ | -------- |
| `Error: No such container: ib2_simulator` | Container not started | Run `docker compose up -d` |
| `Qt: cannot connect to X server` | DISPLAY setting mismatch | Check `$DISPLAY` on both the host and the container |
| ROS setup error | Environment script not sourced | Run `source /opt/ros/melodic/setup.bash` |
| Nothing is displayed | X11 socket not mounted | Check the `/tmp/.X11-unix:` mount |

For detailed logs:

```bash
# Container logs
docker logs ib2_simulator

# Check X11 variables
echo $DISPLAY                      # host
docker exec ib2_simulator bash -c 'echo $DISPLAY'
```

---

## Advanced Usage 🌐

### Customizable parameters

- **HOST_USER_PATH**: Path pointing to the host workspace  
- **Volume mounts**: Shared directories and the X11 socket  
- **Environment variables**: DISPLAY, GPU switching, etc.

### Development tips

- After running `catkin_make` in a ROS workspace, source **devel/setup.bash**  
- Check the Int‑Ball2 API specification and understand its behavior and coordinate systems before implementing your control logic

---

## License Information 📜

For the license of the Int‑Ball2 simulator, refer to the [official JAXA repository](https://github.com/jaxa/int-ball2_simulator).

---

## How to Contribute 🤝

Bug reports and feature suggestions are welcome in **Issues**, and code fixes are welcome as **Pull Requests**.


> **Caution**: This project is under development, and its specifications may change without notice.


