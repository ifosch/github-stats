# github-stats
script to extract some statistics via github api

## Usage

```
docker build . --tag ghs
docker run --rm \
           --volume "$PWD":/home/ghs:Z \
           --env GITHUB_TOKEN=ABC123 \
           ghs:latest \
           bundle exec ruby activity-count.rb \
             --count=comments \
             --repositories=dsager/github-stats \
             --since=2023-06-01
```

## Requirements

The script uses the [octokit gem](https://github.com/octokit/octokit.rb) for accessing the GitHub API.

## LICENSE

[MIT](LICENSE)
