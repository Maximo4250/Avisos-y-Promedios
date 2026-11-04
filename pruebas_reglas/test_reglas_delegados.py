import uuid
import unittest
from test_reglas_spark import ROOT,jwt,request

class ReglasDelegadosTests(unittest.TestCase):
    def setUp(self):
        self.uid='delegado-'+uuid.uuid4().hex
        self.token=jwt(self.uid)
        self.id=str(uuid.uuid4())
        self.path='/ciclos/2026/cursos/4b/avisos/aviso_'+self.id
        self.permiso='/usuarios/'+self.uid+'/permisos/delegado'
    def asignar(self,curso='4b',ciclo=2026,activo=True):
        return request('PATCH',self.permiso,{'fields':{
            'curso':{'stringValue':curso},'ciclo':{'integerValue':str(ciclo)},
            'activo':{'booleanValue':activo}}},'owner')
    def publicar(self,token=None,path=None,**extra):
        campos={'autor_uid':{'stringValue':self.uid},'curso':{'stringValue':'4b'},
            'ciclo':{'integerValue':'2026'},'dia':{'stringValue':'Ju'},
            'archivado':{'booleanValue':False},'datos':{'mapValue':{'fields':{
                'id':{'stringValue':self.id},'materia':{'stringValue':'Matemática'},
                'tipo':{'stringValue':'evaluacion'},'detalle':{'stringValue':'Funciones'},
                'fecha':{'stringValue':'2026-11-12'}}}}}
        campos.update(extra)
        doc=ROOT.replace('http://127.0.0.1:8787/v1/','')+(path or self.path)
        return request('POST',':commit',{'writes':[{'update':{'name':doc,'fields':campos},
            'updateTransforms':[{'fieldPath':'creada_en','setToServerValue':'REQUEST_TIME'}]}]},self.token if token is None else token)
    def test_estudiante_no_publica(self):self.assertEqual(self.publicar()[0],403)
    def test_delegado_publica_y_el_aviso_es_legible(self):
        self.assertEqual(self.asignar()[0],200)
        self.assertEqual(self.publicar()[0],200)
        self.assertEqual(request('GET',self.path)[0],200)
    def test_no_puede_asignarse_ni_revocar_su_propio_cargo(self):
        self.asignar()
        self.assertEqual(request('PATCH',self.permiso,{'fields':{'activo':{'booleanValue':True}}},self.token)[0],403)
        self.assertEqual(request('DELETE',self.permiso,token=self.token)[0],403)
    def test_no_puede_asignar_a_otra_cuenta(self):
        self.assertEqual(request('PATCH','/usuarios/otra/permisos/delegado',{'fields':{'activo':{'booleanValue':True}}},self.token)[0],403)
    def test_solo_lee_su_permiso_sin_listar_otros(self):
        self.asignar()
        self.assertEqual(request('GET',self.permiso,token=self.token)[0],200)
        self.assertEqual(request('GET',self.permiso,token=jwt('otra'))[0],403)
        self.assertEqual(request('GET',self.permiso.rsplit('/',1)[0],token=self.token)[0],403)
    def test_otro_curso_o_ciclo_no_publica_en_4b(self):
        self.asignar(curso='5a');self.assertEqual(self.publicar()[0],403)
        self.asignar(ciclo=2027);self.assertEqual(self.publicar()[0],403)
    def test_revocar_bloquea_inmediatamente_nuevas_escrituras(self):
        self.asignar(activo=False);self.assertEqual(self.publicar()[0],403)
    def test_delegado_no_sobrescribe_documentos_legados(self):
        self.asignar();self.assertEqual(self.publicar(path='/avisos_semana/Lu')[0],403)
    def test_no_suplanta_autor_no_agrega_campos_extra(self):
        self.asignar()
        self.assertEqual(self.publicar(autor_uid={'stringValue':'otra'})[0],403)
        self.assertEqual(self.publicar(admin={'booleanValue':True})[0],403)
    def test_no_edita_ni_borra_avisos_publicados(self):
        self.asignar();self.assertEqual(self.publicar()[0],200)
        self.assertEqual(self.publicar()[0],403)
        self.assertEqual(request('DELETE',self.path,token=self.token)[0],403)
    def test_invitado_no_publica_ni_lee_permisos(self):
        self.asignar()
        self.assertEqual(self.publicar(token='')[0],403)
        self.assertEqual(request('GET',self.permiso)[0],403)
    def test_no_usa_namespace_alternativo_para_duplicar_4b(self):
        self.asignar()
        self.assertEqual(self.publicar(path='/ciclos/2026/cursos/4b/avisos_semana/delegado_'+self.id)[0],403)
    def test_funciona_en_otro_curso_habilitado(self):
        self.asignar(curso='5a')
        request('PATCH','/ciclos/2026/cursos/5a',{'fields':{'disponible':{'booleanValue':True}}},'owner')
        self.assertEqual(self.publicar(path='/ciclos/2026/cursos/5a/avisos/aviso_'+self.id,curso={'stringValue':'5a'})[0],200)

if __name__=='__main__':unittest.main()
