import uuid
import unittest
from test_reglas_spark import ROOT, jwt, request

class ReglasNotasTests(unittest.TestCase):
    def setUp(self):
        self.uid='sync-'+uuid.uuid4().hex
        self.token=jwt(self.uid)
        self.path='/usuarios/'+self.uid+'/libretas/2026_4b/notas/nota-1'
    def guardar(self,path=None,token=None,**changes):
        fields={'materia':{'stringValue':'Matemáticas'},'valor':{'doubleValue':9},
            'doble':{'booleanValue':False},'borrada':{'booleanValue':False},
            'curso':{'stringValue':'4b'},'ciclo':{'integerValue':'2026'}}
        fields.update(changes)
        doc=ROOT.replace('http://127.0.0.1:8787/v1/','')+(path or self.path)
        return request('POST',':commit',{'writes':[{'update':{'name':doc,'fields':fields},
            'updateTransforms':[{'fieldPath':'actualizada_en','setToServerValue':'REQUEST_TIME'}]}]},self.token if token is None else token)
    def test_propietario_crea_lee_y_lista(self):
        self.assertEqual(self.guardar()[0],200)
        self.assertEqual(request('GET',self.path,token=self.token)[0],200)
        self.assertEqual(request('GET',self.path.rsplit('/',1)[0],token=self.token)[0],200)
    def test_otro_usuario_no_lee_ni_escribe(self):
        self.assertEqual(self.guardar()[0],200)
        self.assertEqual(request('GET',self.path,token=jwt('otro'))[0],403)
        self.assertEqual(self.guardar(token=jwt('otro'))[0],403)
    def test_invitado_y_anonimo_no_acceden(self):
        self.assertEqual(self.guardar(token='')[0],403)
        self.assertEqual(self.guardar(token=jwt(self.uid,'anonymous'))[0],403)
    def test_borrado_gana_no_resucita(self):
        self.assertEqual(self.guardar()[0],200)
        self.assertEqual(self.guardar(borrada={'booleanValue':True})[0],200)
        self.assertEqual(self.guardar()[0],403)
    def test_valor_es_inmutable(self):
        self.assertEqual(self.guardar()[0],200)
        self.assertEqual(self.guardar(valor={'doubleValue':10})[0],403)
    def test_limites_y_campos_extras(self):
        self.assertEqual(self.guardar(valor={'doubleValue':11})[0],403)
        self.assertEqual(self.guardar(admin={'booleanValue':True})[0],403)
    def test_curso_y_ciclo_deben_coincidir_con_ruta(self):
        self.assertEqual(self.guardar(curso={'stringValue':'otro'})[0],403)
        self.assertEqual(self.guardar(ciclo={'integerValue':'2027'})[0],403)
    def test_no_permite_borrado_fisico(self):
        self.assertEqual(self.guardar()[0],200)
        self.assertEqual(request('DELETE',self.path,token=self.token)[0],403)

if __name__=='__main__':unittest.main()
