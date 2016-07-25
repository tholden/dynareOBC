cd ..
set path=%path%;C:\Program Files (x86)\Pandoc;C:\Program Files\wkhtmltopdf\bin
pandoc README.md -f markdown_github -o ReadMe.pdf -N --toc --wrap=none -V papersize=A4 -V fontsize=10pt -V lang=en-GB -V documentclass=article -V margin-left=2.54cm -V margin-right=2.54cm -V margin-top=2.54cm -V margin-bottom=2.54cm -V fontfamily=tgpagella -V links-as-notes -V colorlinks
cd DevTools
