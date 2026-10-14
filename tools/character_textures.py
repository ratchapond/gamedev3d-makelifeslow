"""Original small seamless normal maps for cloth, leather, straw and animal coats."""
from pathlib import Path
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'game/assets/textures/characters'
OUT.mkdir(parents=True,exist_ok=True)
N=512;y,x=np.mgrid[:N,:N]/N;rng=np.random.default_rng(7129)
def noise(scale,aspect=1):
 white=rng.normal(size=(N,N));fx=np.fft.fftfreq(N)[None,:]*N;fy=np.fft.fftfreq(N)[:,None]*N
 field=np.fft.ifft2(np.fft.fft2(white)*np.exp(-((fx/scale)**2+(fy/(scale*aspect))**2))).real
 return field/max(field.std(),1e-6)
def save(name,h,strength):
 dx=(np.roll(h,-1,1)-np.roll(h,1,1))*strength;dy=(np.roll(h,-1,0)-np.roll(h,1,0))*strength
 normal=np.stack([-dx,-dy,np.ones_like(dx)],axis=-1);normal/=np.linalg.norm(normal,axis=-1,keepdims=True)
 Image.fromarray(np.uint8(np.clip(normal*.5+.5,0,1)*255)).save(OUT/(name+'_normal.png'),optimize=True)
weave=(np.sin(x*np.pi*128)*np.cos(y*np.pi*128))*.09+noise(100)*.012
save('linen',weave,1.6)
save('denim',np.sin((x+y)*np.pi*144)*.08+noise(120)*.018,1.8)
save('leather',noise(80)*.07+noise(18)*.03,2)
save('straw',np.sin(x*np.pi*56)*.13+np.sin(y*np.pi*112)*.045,2)
save('fur',noise(85,.2)*.09+noise(140,.3)*.025,2)
save('fleece',noise(42)*.10+noise(90)*.06,2)
save('feather',np.sin(x*np.pi*70+np.sin(y*np.pi*8)*.45)*.065+noise(80,.2)*.025,2)
print('Generated seven 512px character material normal maps.')
