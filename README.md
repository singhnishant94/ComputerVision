# ComputerVision
Automatic Panoramic Image Stitching
##Contributors:
Nishant Kumar Singh 120050043
Deependra Patel 120050032

##HOW TO USE
Put all images in a folder(can try data/)
Run 
'connected_components(dir_path, color)' in matlab
Where dir_path is the path to the directory of all your images
color = 0 for black & white output
color = 1 for colored output

Output is written as files:
output1.jpg
output2.jpg
...
where 1,2 are the connected component. eg if there is only 1 panaroma in all images, then there will be single file named 'output1.jpg'
