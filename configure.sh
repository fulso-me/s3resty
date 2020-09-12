#!/bin/bash

NAME=openresty
VERSION=1.15.8
PATCH_VERSION=3

printf '\nConfiguring Dockerfile.\n'
# Variables have to be declared on the same line.
VERSION=$VERSION \
  PATCH_VERSION=$PATCH_VERSION \
  envsubst < tmp_Dockerfile > Dockerfile

printf '\nMaking build.sh executable.\n'
cat > build.sh <<- EOM
#!/bin/bash

printf '\nBuilding docker image.\n'
docker build . -t fulsome/"$NAME:$VERSION.$PATCH_VERSION" -t fulsome/"$NAME:$VERSION"

if [ $? == 0 ]
then
  printf '\nBuilt image at fulsome/%s:%s\n' "$NAME" "$VERSION.$PATCH_VERSION"
  printf 'with a size of %s\n' "\$(docker images | grep -P 'fulsome/'"$NAME"'\s*'"$VERSION.$PATCH_VERSION" | grep -oP '\d*\.?\d*(k|M|G)B')"
  
  printf '\nWriting commit file\n'
  printf 'docker push fulsome/"%s:%s.%s"\n' "$NAME" "$VERSION" "$PATCH_VERSION" > commit.sh
  printf 'docker push fulsome/"%s:%s"\n' "$NAME" "$VERSION" >> commit.sh
  chmod +x commit.sh
else
  exit 1
fi
EOM
chmod +x build.sh

printf '\nMaking clean.sh executable.\n'
cat > clean.sh <<- EOM
#!/bin/bash

# clean in reverse order
rm "commit.sh"
rm "build.sh"

rm "Dockerfile"

rm "clean.sh"
EOM
chmod +x clean.sh
