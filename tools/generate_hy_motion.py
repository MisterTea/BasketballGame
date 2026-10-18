"""Generate real HY-Motion 1.0 clips locally, then export rotations to Godot's XYZW format.

No replacement model or hand-authored motion is used. Qwen is optionally loaded in
8-bit to fit a 16 GB GPU; the standard HY-Motion checkpoint stays full precision.
"""
import argparse
import gc
import hashlib
import json
import os
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RUNTIME = ROOT / '.runtime'
UPSTREAM = RUNTIME / 'HY-Motion-1.0'
MODELS = RUNTIME / 'models'
OUTPUT = ROOT / 'animations' / 'hy_motion'
PROMPTS = [
    {'name':'idle','text':'A person stands relaxed in place, breathing gently, shifting weight slightly, arms resting naturally at the sides.','duration':3.0,'seed':3101,'loop':True},
    {'name':'run','text':'A basketball player runs forward at a steady pace, pumping bent arms naturally, alternating strong strides, remaining upright.','duration':3.0,'seed':3102,'loop':True},
    {'name':'dribble','text':'A basketball player runs forward while repeatedly dribbling a basketball with the right hand, knees slightly bent, left arm balancing.','duration':3.0,'seed':3103,'loop':True},
    {'name':'defense','text':'A basketball defender crouches in place, feet wide, knees bent, arms spread, making small lateral weight shifts while guarding.','duration':3.0,'seed':3104,'loop':True},
    {'name':'shoot','text':'A basketball player bends the knees, raises both hands above the forehead, jumps and shoots, extending the right elbow and flicking the wrist.','duration':3.0,'seed':3105,'loop':False},
    {'name':'pass','text':'A basketball player holds both hands near the chest, then extends both arms forward for a strong chest pass and returns upright.','duration':2.5,'seed':3106,'loop':False},
    {'name':'dunk','text':'A basketball player bends the knees, jumps high, raises the right arm overhead, slams a basketball downward, then lands with bent knees.','duration':3.5,'seed':3107,'loop':False},
    {'name':'block','text':'A basketball defender jumps straight up with both arms fully extended overhead to block a shot, then lands on both feet.','duration':2.5,'seed':3108,'loop':False},
    {'name':'steal','text':'A basketball defender crouches, lunges slightly forward and reaches the right hand low to swipe a ball, then returns to a balanced stance.','duration':2.5,'seed':3109,'loop':False},
    {'name':'stun','text':'A person staggers backward after being bumped, flings both arms outward for balance, bends the knees, and recovers without falling.','duration':2.5,'seed':3110,'loop':False},
    {'name':'layup','text':'A basketball player takes two running steps, jumps off the left foot, lifts the right knee, extends the right arm upward to gently lay the ball into the basket with one hand, then lands and recovers.','duration':3.0,'seed':3111,'loop':False},
]

def save_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, separators=(',',':')), encoding='utf-8')

def clip_record(path):
    clip=json.loads(path.read_text())
    return {'name':clip['name'],'frames':clip['frames'],'seed':clip['seed'],'prompt':clip['prompt'],'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}

def prepare():
    import numpy as np
    OUTPUT.mkdir(parents=True, exist_ok=True)
    assets = UPSTREAM / 'scripts/gradio/static/assets/dump_wooden'
    positions = np.fromfile(assets/'j_template.bin', dtype='<f4').reshape(-1,3)
    parents = np.fromfile(assets/'kintree.bin', dtype='<i4')
    names = json.loads((assets/'joint_names.json').read_text())
    assert len(names) == len(parents) == len(positions) == 52
    revision = subprocess.check_output(['git','-C',str(UPSTREAM),'rev-parse','HEAD'],text=True).strip()
    save_json(OUTPUT/'skeleton.json', {'format':1,'name':'HY-Motion SMPL-H','joint_count':52,'animated_joints':22,'joint_names':names,'parents':parents.tolist(),'rest_positions':positions.astype(float).tolist(),'up_axis':'Y','forward_axis':'+Z','units':'meters','source_revision':revision})
    save_json(ROOT/'tools/hy_motion_prompts.json',PROMPTS)
    return revision

def encode(text_mode):
    import torch
    from transformers import AutoModelForCausalLM, BitsAndBytesConfig
    os.environ['USE_HF_MODELS']='0'
    sys.path.insert(0,str(UPSTREAM))
    from hymotion.network.text_encoders import text_encoder as te
    te.SENTENCE_EMB_LAYOUT['clipl']['module_path']=str(MODELS/'clip-vit-large-patch14')
    te.LLM_ENCODER_LAYOUT['qwen3']['module_path']=str(MODELS/'Qwen3-8B')
    if text_mode == 'int8':
        class EightBitQwen:
            @staticmethod
            def from_pretrained(path, **kwargs):
                return AutoModelForCausalLM.from_pretrained(path,**kwargs,quantization_config=BitsAndBytesConfig(load_in_8bit=True),device_map={'':0},attn_implementation='sdpa')
        te.LLM_ENCODER_LAYOUT['qwen3']['text_encoder_class']=EightBitQwen
    print('Loading official CLIP and Qwen3-8B text encoders, mode='+text_mode,flush=True)
    encoder=te.HYTextModel(max_length_llm=128,enable_llm_padding=False)
    if text_mode == 'int8':
        encoder.sentence_emb_text_encoder.to('cuda')
    encoder.eval()
    cache={}
    with torch.inference_mode():
        for prompt in PROMPTS:
            started=time.time()
            vector,context,length=encoder.encode([prompt['text']])
            cache[prompt['name']]={'text_vec_raw':vector.float().cpu(),'text_ctxt_raw':context.float().cpu(),'text_ctxt_raw_length':length.cpu()}
            print('ENCODED',prompt['name'],'tokens',int(length[0]),'seconds',round(time.time()-started,2),flush=True)
    torch.save(cache,RUNTIME/'text_embeddings.pt')
    del encoder, cache
    gc.collect()
    torch.cuda.empty_cache()
    print('ENCODERS UNLOADED',flush=True)

def export_clip(prompt, output, source_revision):
    import numpy as np
    import torch
    from scipy.spatial.transform import Rotation
    from hymotion.utils.geometry import rot6d_to_rotation_matrix
    matrices=rot6d_to_rotation_matrix(output['rot6d'][0].float()).cpu().numpy()
    translation=output['transl'][0].float().cpu().numpy()
    forward=matrices[0,0]@np.array([0.,0.,1.])
    yaw=float(np.arctan2(forward[0],forward[2]))
    normalize=Rotation.from_rotvec([0,-yaw,0]).as_matrix()
    matrices[:,0]=normalize[None]@matrices[:,0]
    quaternions=Rotation.from_matrix(matrices.reshape(-1,3,3)).as_quat().reshape(-1,22,4)
    # Continuity matters for interpolation and loop seam selection.
    for frame in range(1,len(quaternions)):
        flip=np.sum(quaternions[frame-1]*quaternions[frame],axis=-1)<0
        quaternions[frame,flip]*=-1
    first,last=0,len(quaternions)
    if prompt['name'] in ('run','dribble','defense'):
        best=(float('inf'),0,len(quaternions))
        weights=np.ones(22); weights[[1,2,4,5,7,8,10,11]]=3
        for a in range(10,min(40,len(quaternions)-35)):
            for b in range(a+20,min(a+46,len(quaternions))):
                similarity=np.abs(np.sum(quaternions[a]*quaternions[b],axis=-1))
                cost=float(np.average(1-similarity,weights=weights))
                if cost<best[0]: best=(cost,a,b)
        _,first,last=best
    quaternions=quaternions[first:last]
    root_y=translation[first:last,1]
    assert np.isfinite(quaternions).all() and len(quaternions)>=20
    skeleton=json.loads((OUTPUT/'skeleton.json').read_text())
    rest=np.array(skeleton['rest_positions'])
    rotations=Rotation.from_quat(quaternions.reshape(-1,4)).as_matrix().reshape(-1,22,3,3)
    positions=np.zeros((len(quaternions),22,3)); global_rotations=np.zeros_like(rotations)
    for joint in range(22):
        parent=skeleton['parents'][joint]
        if parent<0:
            positions[:,joint]=rest[joint]
            global_rotations[:,joint]=rotations[:,joint]
        else:
            positions[:,joint]=positions[:,parent]+np.einsum('bij,j->bi',global_rotations[:,parent],rest[joint]-rest[parent])
            global_rotations[:,joint]=global_rotations[:,parent]@rotations[:,joint]
    hand_height=positions[:,[20,21],1].max(axis=1)-positions[:,15,1]
    event_phase=float(np.argmax(hand_height)/max(1,len(quaternions)-1))
    grounded_root_y=-positions[:,[7,8,10,11],1].min(axis=1)+0.0425
    clip={'grounded_root_y':grounded_root_y.round(6).tolist(),'event_phase':event_phase,'format':1,'name':prompt['name'],'source':'Tencent HY-Motion-1.0 standard','machine_generated':True,'prompt':prompt['text'],'seed':prompt['seed'],'fps':30,'loop':prompt['loop'],'frames':len(quaternions),'joint_count':22,'quaternions_xyzw':quaternions.round(7).tolist(),'root_y':root_y.round(6).tolist(),'neutral_root_y':float(np.percentile(translation[:,1],15)),'source_frame_range':[first,last],'heading_removed_radians':yaw,'horizontal_root_motion':'discarded; game simulation owns court movement','source_revision':source_revision}
    save_json(OUTPUT/(prompt['name']+'.json'),clip)
    return clip_record(OUTPUT/(prompt['name']+'.json'))

def generate(steps, source_revision, only):
    import numpy as np
    import torch
    import yaml
    os.chdir(UPSTREAM)
    sys.path.insert(0,str(UPSTREAM))
    from hymotion.utils.loaders import load_object
    path=MODELS/'tencent/HY-Motion-1.0'
    config=yaml.safe_load((path/'config.yml').read_text())
    pipeline=load_object(config['train_pipeline'],config['train_pipeline_args'],network_module=config['network_module'],network_module_args=config['network_module_args'])
    print('Loading official standard HY-Motion 1.0 checkpoint',flush=True)
    checkpoint=torch.load(path/'latest.ckpt',map_location='cpu',weights_only=False)
    missing,unexpected=pipeline.load_state_dict(checkpoint['model_state_dict'],strict=False)
    core_missing=[k for k in missing if k.startswith('motion_transformer.')]
    assert not core_missing, f'Missing pretrained motion weights: {core_missing}'
    del checkpoint
    gc.collect()
    pipeline.eval().to('cuda')
    pipeline.validation_steps=steps
    cache=torch.load(RUNTIME/'text_embeddings.pt',map_location='cpu',weights_only=True)
    raw_dir=RUNTIME/'raw_motion'; raw_dir.mkdir(exist_ok=True)
    clips=[]
    for prompt in PROMPTS:
        if only and prompt['name'] not in only:
            existing=OUTPUT/(prompt['name']+'.json')
            if existing.exists(): clips.append(clip_record(existing))
            continue
        raw=raw_dir/(prompt['name']+'.npz')
        started=time.time()
        if raw.exists():
            data=np.load(raw)
            output={'rot6d':torch.from_numpy(data['rot6d']),'transl':torch.from_numpy(data['transl'])}
            print('USING GENERATED CACHE',prompt['name'],flush=True)
        else:
            embeddings={k:v.to('cuda') for k,v in cache[prompt['name']].items()}
            # Only sample valid frames; official temporal attention already masks padding.
            pipeline.train_frames=int(round(prompt['duration']*30))
            torch.cuda.reset_peak_memory_stats()
            with torch.inference_mode():
                output=pipeline.generate(prompt['text'],[prompt['seed']],prompt['duration'],cfg_scale=5.0,hidden_state_dict=embeddings)
            np.savez_compressed(raw,rot6d=output['rot6d'].cpu().numpy(),transl=output['transl'].cpu().numpy())
            print('GENERATED',prompt['name'],'seconds',round(time.time()-started,2),'peak_vram_gb',round(torch.cuda.max_memory_allocated()/2**30,2),flush=True)
        clips.append(export_clip(prompt,output,source_revision))
        del output
        torch.cuda.empty_cache()
    sources=json.loads((RUNTIME/'model_sources.json').read_text())
    sources={repo:{k:v for k,v in info.items() if k!='local_dir'} for repo,info in sources.items()}
    save_json(OUTPUT/'provenance.json',{'generator':'Tencent HY-Motion-1.0 standard (1B)','machine_generated':True,'executed_locally':True,'device':torch.cuda.get_device_name(),'motion_precision':'float32','text_encoder':'Qwen3-8B int8 + CLIP float32; encoders unloaded before motion inference','steps':steps,'guidance_scale':5.0,'upstream_commit':source_revision,'model_sources':sources,'clips':clips,'processing':['source 6D columns converted with upstream rot6d_to_rotation_matrix','quaternions stored in Godot XYZW order','initial root yaw removed','horizontal root displacement discarded','loop cycle selected by pose similarity','peak wrist pose tagged for gameplay event alignment']})
    print('GENERATION COMPLETE',len(clips),'clips',flush=True)

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--phase',choices=['prepare','encode','generate','export','all'],default='all')
    parser.add_argument('--text-mode',choices=['int8','cpu'],default='int8')
    parser.add_argument('--steps',type=int,default=50)
    parser.add_argument('--only',nargs='*')
    args=parser.parse_args()
    revision=prepare()
    if args.phase == 'export':
        import numpy as np
        import torch
        sys.path.insert(0,str(UPSTREAM))
        clips=[]
        for prompt in PROMPTS:
            data=np.load(RUNTIME/'raw_motion'/(prompt['name']+'.npz'))
            output={'rot6d':torch.from_numpy(data['rot6d']),'transl':torch.from_numpy(data['transl'])}
            clips.append(export_clip(prompt,output,revision))
        record=json.loads((OUTPUT/'provenance.json').read_text())
        record['clips']=clips
        record['model_sources']={repo:{k:v for k,v in info.items() if k!='local_dir'} for repo,info in record['model_sources'].items()}
        if 'peak wrist pose tagged for gameplay event alignment' not in record['processing']:
            record['processing'].append('peak wrist pose tagged for gameplay event alignment')
        save_json(OUTPUT/'provenance.json',record)
        print('EXPORTED',len(clips),'previously generated clips',flush=True)
    if args.phase in ('encode','all'): encode(args.text_mode)
    if args.phase in ('generate','all'): generate(args.steps,revision,args.only)
