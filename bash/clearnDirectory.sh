# chmod +x clearnDirectory.sh 
dotnet clean
for i in 1 2; do
  find . -type d \( -name "bin" -o -name "obj" -o -name "coverage" -o -name "build" -o -name "node_modules" \) -exec rm -r {} \;
done