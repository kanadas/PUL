from PIL import Image

im = Image.open('invaders/sprites.png', 'r')
out = open("sprites.hex", "w")

pix = list(im.getdata())

for (r,g,b,a) in pix:
    if r+g+b > 300 :
        out.write("f\n")
    else:
        out.write("0\n")

