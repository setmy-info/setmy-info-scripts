
- [] Task: Fix src/main/groovy/lib/versions-spider.groovy, because some URL-s are broken.
  Try to download page versions, grep from their texts and relevant URL-s or information to produce download URL.
  First, test the script is able to download scrap the page. Broken are files and described in
  src/main/resources/tasklist/BROKEN-LINES.txt. Re check are some downloads relevant, somehow, short curling or
  something. Others should not be investigated and changes in that file. Other files
  should not be changed.