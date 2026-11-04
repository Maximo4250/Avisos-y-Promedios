import uuid
import test_reglas_delegados as helpers
from test_reglas_spark import ROOT,jwt,request
import unittest

class ArchivadoTests(unittest.TestCase):
    def setUp(self):
        self.base=helpers.ReglasDelegadosTests()
        self.base.setUp()
        self.base.asignar()
        self.assertEqual(self.base.publicar()[0],200)
    def archivar(self,token=None,extra=None,valor=True):
        b=self.base
        fields={'archivado':{'booleanValue':valor},
            'archivado_por':{'stringValue':b.uid}}
        fields.update(extra or {})
        doc=ROOT.replace('http://127.0.0.1:8787/v1/','')+b.path
        return request('POST',':commit',{'writes':[{'update':{'name':doc,'fields':fields},
            'updateMask':{'fieldPaths':list(fields)},
            'updateTransforms':[{'fieldPath':'archivado_en','setToServerValue':'REQUEST_TIME'}]}]},token or b.token)
    def test_archiva_aviso_propio_y_conserva_contenido(self):
        self.assertEqual(self.archivar()[0],200)
        fields=request('GET',self.base.path)[1]['fields']
        self.assertTrue(fields['archivado']['booleanValue'])
        self.assertIn('datos',fields)
    def test_archiva_aviso_de_otro_delegado_del_mismo_curso(self):
        otro='delegado-'+uuid.uuid4().hex
        request('PATCH','/usuarios/'+otro+'/permisos/delegado',{'fields':{
            'activo':{'booleanValue':True},'curso':{'stringValue':'4b'},'ciclo':{'integerValue':'2026'}}},'owner')
        self.base.uid=otro
        self.assertEqual(self.archivar(jwt(otro))[0],200)
    def test_estudiante_no_archiva(self):
        self.assertEqual(self.archivar(jwt('estudiante'))[0],403)
    def test_delegado_revocado_no_archiva(self):
        self.base.asignar(activo=False)
        self.assertEqual(self.archivar()[0],403)
    def test_delegado_otro_curso_no_archiva(self):
        self.base.asignar(curso='5a')
        self.assertEqual(self.archivar()[0],403)
    def test_no_altera_contenido_al_archivar(self):
        self.assertEqual(self.archivar(extra={'dia':{'stringValue':'Lu'}})[0],403)
    def test_no_suplanta_quien_archiva(self):
        self.assertEqual(self.archivar(extra={'archivado_por':{'stringValue':'otro'}})[0],403)
    def test_no_restaura_ni_borra_fisicamente(self):
        self.assertEqual(self.archivar()[0],200)
        self.assertEqual(self.archivar(valor=False)[0],403)
        self.assertEqual(request('DELETE',self.base.path,token=self.base.token)[0],403)
    def trasladar(self,alterar=False):
        b=self.base
        origen='origen_'+uuid.uuid4().hex
        datos={'materia':{'stringValue':'Lengua'},'detalle':{'stringValue':'Leer texto'},'tipo':{'stringValue':'tarea'}}
        request('PATCH','/avisos_semana/'+origen,{'fields':{'dia':{'stringValue':'Ma'},
            'evalucaciones':{'arrayValue':{'values':[{'mapValue':{'fields':datos}}]}}}},'owner')
        if alterar:datos['detalle']={'stringValue':'Dato alterado'}
        campos={'datos':{'mapValue':{'fields':datos}},'dia':{'stringValue':'Ma'},
            'curso':{'stringValue':'4b'},'ciclo':{'integerValue':'2026'},
            'autor_uid':{'stringValue':'administrador'},'archivado':{'booleanValue':False},
            'origen_documento':{'stringValue':origen},'origen_indice':{'integerValue':'0'}}
        doc=ROOT.replace('http://127.0.0.1:8787/v1/','')+'/ciclos/2026/cursos/4b/avisos/legado_'+origen+'_0'
        return request('POST',':commit',{'writes':[{'update':{'name':doc,'fields':campos},
            'updateTransforms':[{'fieldPath':'creada_en','setToServerValue':'REQUEST_TIME'}]}]},b.token)
    def test_delegado_no_puede_trasladar_ni_copiar_origen(self):
        result=self.trasladar();self.assertEqual(result[0],403,result)
    def test_traslado_no_inventa_contenido(self):
        self.assertEqual(self.trasladar(alterar=True)[0],403)
    def test_no_se_crean_documentos_en_coleccion_antigua(self):
        self.assertEqual(self.base.publicar(path='/avisos_semana/delegado_'+self.base.id)[0],403)
