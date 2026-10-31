"""Pruebas contra Firestore Emulator local. Nunca usa un proyecto real.

Iniciar el emulador con estas reglas, proyecto demo-ap-spark y puerto 8787.
Ejecutar: python -m unittest discover -s pruebas_reglas -v
"""
import base64
import copy
import json
import time
import unittest
import urllib.request
import urllib.error
import uuid

ROOT='http://127.0.0.1:8787/v1/projects/demo-ap-spark/databases/(default)/documents'

def jwt(uid,provider='password'):
    def part(value):return base64.urlsafe_b64encode(json.dumps(value).encode()).decode().rstrip('=')
    return part({'alg':'none','typ':'JWT'})+'.'+part({'aud':'demo-ap-spark',
        'iss':'https://securetoken.google.com/demo-ap-spark','sub':uid,'user_id':uid,
        'iat':int(time.time()),'exp':int(time.time())+3600,'auth_time':int(time.time()),
        'email':'alumno@example.com','email_verified':False,
        'firebase':{'sign_in_provider':provider,'identities':{}}})+'.'

def request(method,path='',value=None,token=None):
    headers={'Content-Type':'application/json'}
    if token:headers['Authorization']='Bearer '+token
    req=urllib.request.Request(ROOT+path, data=None if value is None else json.dumps(value).encode(),
        headers=headers,method=method)
    try:
        with urllib.request.urlopen(req,timeout=12) as result:
            return result.status,json.loads(result.read() or b'{}')
    except urllib.error.HTTPError as e:return e.code,json.loads(e.read())

def create(uid,extra=None):
    fields={'usuario':{'stringValue':'Estudiante'},'curso_predeterminado':{'stringValue':'4b'},
        'ciclo':{'integerValue':'2026'}}
    fields.update(extra or {})
    return {'writes':[{'update':{'name':ROOT.replace('http://127.0.0.1:8787/v1/','')+'/usuarios/'+uid,'fields':fields},
        'updateTransforms':[{'fieldPath':key,'setToServerValue':'REQUEST_TIME'} for key in ['creada_en','actualizada_en']]}]}

def change(uid,field,value):
    return {'writes':[{'update':{'name':ROOT.replace('http://127.0.0.1:8787/v1/','')+'/usuarios/'+uid,
        'fields':{field:value}},'updateMask':{'fieldPaths':[field]},
        'updateTransforms':[{'fieldPath':'actualizada_en','setToServerValue':'REQUEST_TIME'}]}]}

class RulesSparkTests(unittest.TestCase):
    def setUp(self):
        self.uid='test-'+uuid.uuid4().hex
        self.token=jwt(self.uid)
        result=request('POST',':commit',create(self.uid),self.token)
        self.assertEqual(result[0],200,result)

    def deny(self,result):self.assertEqual(result[0],403,result)
    def test_owner_can_read_own_profile(self):
        self.assertEqual(request('GET','/usuarios/'+self.uid,token=self.token)[0],200)
    def test_other_user_and_guest_cannot_read(self):
        self.deny(request('GET','/usuarios/'+self.uid,token=jwt('otra-persona')))
        self.deny(request('GET','/usuarios/'+self.uid))
    def test_cannot_list_profiles(self):
        query={'structuredQuery':{'from':[{'collectionId':'usuarios'}]}}
        self.deny(request('POST',':runQuery',query,self.token))
    def test_cannot_create_profile_for_someone_else(self):
        self.deny(request('POST',':commit',create('persona-ajena'),self.token))
    def test_anonymous_cannot_create_profile(self):
        self.deny(request('POST',':commit',create('anonimo'),jwt('anonimo','anonymous')))
    def test_no_password_or_admin_fields(self):
        for key in ['password','password_hash','rol','admin','sesion_version']:
            uid=uuid.uuid4().hex
            self.deny(request('POST',':commit',create(uid,{key:{'stringValue':'admin'}}),jwt(uid)))
            self.deny(request('POST',':commit',change(self.uid,key,{'stringValue':'admin'}),self.token))
    def test_course_requires_enabled_catalog(self):
        self.deny(request('POST',':commit',change(self.uid,'curso_predeterminado',{'stringValue':'inexistente'}),self.token))
        seed=request('PATCH','/ciclos/2026/cursos/curso-prueba',{'fields':{'disponible':{'booleanValue':True}}},'owner')
        self.assertEqual(seed[0],200,seed)
        result=request('POST',':commit',change(self.uid,'curso_predeterminado',{'stringValue':'curso-prueba'}),self.token)
        self.assertEqual(result[0],200,result)
    def test_year_and_name_are_not_freely_editable(self):
        self.deny(request('POST',':commit',change(self.uid,'ciclo',{'integerValue':'2027'}),self.token))
        self.deny(request('POST',':commit',change(self.uid,'usuario',{'stringValue':'Otro nombre'}),self.token))
    def test_dates_cannot_be_rewritten(self):
        self.deny(request('POST',':commit',change(self.uid,'creada_en',{'timestampValue':'2020-01-01T00:00:00Z'}),self.token))
    def test_cannot_delete_profile(self):
        self.deny(request('DELETE','/usuarios/'+self.uid,token=self.token))
    def test_cannot_modify_shared_notices_or_catalog(self):
        self.deny(request('PATCH','/avisos_semana/Lu',{'fields':{}},self.token))
        self.deny(request('PATCH','/ciclos/2026/cursos/4b',{'fields':{}},self.token))
    def test_private_collections_are_denied(self):
        for collection in ['_credenciales','_dispositivos','_recuperaciones']:
            self.deny(request('GET',f'/{collection}/cualquier-id',token=self.token))


    def test_nexus_rules_are_preserved(self):
        name=ROOT.replace('http://127.0.0.1:8787/v1/','')+f'/nexus_users/{self.uid}/state/current'
        fields={'schemaVersion':{'integerValue':'1'}}
        for key in ['tasks','evaluations','projects','sessions']:fields[key]={'mapValue':{'fields':{}}}
        write={'writes':[{'update':{'name':name,'fields':fields},'updateTransforms':[{'fieldPath':'updatedAt','setToServerValue':'REQUEST_TIME'}]}]}
        result=request('POST',':commit',write,self.token)
        self.assertEqual(result[0],200,result)
        self.assertEqual(request('GET',f'/nexus_users/{self.uid}/state/current',token=self.token)[0],200)
        self.deny(request('GET',f'/nexus_users/{self.uid}/state/current',token=jwt('otra-persona')))

    def test_legacy_namespaces_keep_their_existing_access(self):
        result=request('PATCH','/namespace_legacy/prueba',{'fields':{'prueba':{'booleanValue':True}}})
        self.assertEqual(result[0],200,result)
        self.assertEqual(request('GET','/namespace_legacy/prueba')[0],200)

if __name__=='__main__':unittest.main()
