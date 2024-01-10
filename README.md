# Versioner 

This is a language agnostic git versioning tool using tags.

## Why this repo
There are plenty of tools available that can generate a version based on Git tags, or viceversa.
I decided to roll my own to offer a very simple approach at versioning, without any faff or unnecessary requirements.

Most of them follow the SemVer practices


How to use the docker container:
```shell script
docker run -v $(pwd):/repo --rm dragosd2000/versioner
```

For a specific version, let's say 1.0.2:
```shell script
docker run -v (pwd):/repo --rm dragosd2000/versioner:1.0.16
```

Inside your `Jenkinsfiles`, you should be able to define a container pointing to it to use inside your pipeline, or
just invoke the command above inside a docker container.
