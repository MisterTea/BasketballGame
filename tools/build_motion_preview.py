"""Build a compact GIF from actual Godot-rendered HY-Motion preview frames."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont

root=Path(__file__).resolve().parents[1]
paths=sorted((root/'.runtime/preview_frames').glob('*.png'))
assert len(paths)==180, 'Run Godot with tests/capture_hy_motion.gd first.'
actions=['idle','run','dribble','defense','shoot','pass','dunk','block','steal','stun']
try:
    font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',18)
except OSError:
    font=ImageFont.load_default()
frames=[]
for index,path in enumerate(paths):
    if index%2: continue
    with Image.open(path) as source:
        image=source.convert('RGB').crop((360,290,1090,560))
    canvas=Image.new('RGB',(730,300),(9,19,33))
    canvas.paste(image,(0,30))
    ImageDraw.Draw(canvas).text((12,5),'HY-MOTION 1.0 / '+actions[index//18].upper()+' / LOCAL MODEL OUTPUT',font=font,fill=(255,203,104))
    frames.append(canvas)
palette=frames[0].quantize(colors=96,method=Image.Quantize.MEDIANCUT)
frames=[frame.quantize(palette=palette,dither=Image.Dither.NONE) for frame in frames]
output=root/'docs/hy_motion_preview.gif'
frames[0].save(output,save_all=True,append_images=frames[1:],duration=120,loop=0,optimize=True,disposal=1)
print('Created',output,'frames',len(frames),'bytes',output.stat().st_size)
