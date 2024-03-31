# chmod +x clearnDirectory.sh 
for i in 1 2; do
  find . -type d \( -name "bin" -o -name "obj" -o -name "coverage" -o -name "build" -o -name "node_modules" -o -name "dist" -o -name "cache" -o -name "package-lock.json" \) -exec rm -r {} \;
done

find . -type d \( -name "bin" -o -name "obj" -o -name "coverage" -o -name "build" -o -name "node_modules" -o -name "dist" -o -name "cache" \) -exec rm -rf {} +