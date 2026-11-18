"""Pruebas de mensajeria con tres cuentas existentes y limpieza exclusiva de pruebas."""
from uuid import uuid4
from sqlalchemy import select, delete
from database import SessionLocal
from models import Mensaje
from test_blog import login
from test_usuarios import call


def main():
    tokens = []
    ids = []
    marca = 'Prueba mensajeria ' + uuid4().hex
    try:
        for etiqueta in ('administrador', 'usuario normal', 'segundo usuario normal'):
            tokens.append(login(etiqueta))
        admin, a, b = tokens
        cuentas = [call('/auth/me', token=t) for t in tokens]
        assert [u['rol'] for u in cuentas] == ['administrador','usuario','usuario']
        _, uid, otro = [u['id_usuario'] for u in cuentas]
        assert len({u['id_usuario'] for u in cuentas}) == 3
        datos = dict(id_receptor=otro, mensaje=marca)
        call('/mensajes', expected=401)
        call('/mensajes','POST',datos,expected=401)
        call('/mensajes/conversaciones',expected=401)
        call('/mensajes/no-leidos',expected=401)
        for d in [dict(datos,mensaje='   '),dict(datos,mensaje='x'*4001),
                  dict(datos,id_emisor=otro),dict(datos,id_receptor=uid),dict(datos,id_receptor=0)]:
            call('/mensajes','POST',d,a,422)
        call('/mensajes','POST',dict(datos,id_receptor=4294967295),a,404)
        antes = call('/mensajes/no-leidos',token=b)['total']
        m = call('/mensajes','POST',datos,a,201)
        ids.append(m['id_mensaje']); ruta = '/mensajes/'+str(ids[0])
        assert m['id_emisor']==uid and m['id_receptor']==otro and not m['leido']
        assert call(ruta,token=b)['mensaje']==marca
        call(ruta,token=a)
        call(ruta,token=admin,expected=404)
        call(ruta+'/leido','PUT',token=admin,expected=404)
        call(ruta+'/leido','PUT',token=a,expected=403)
        call(ruta,expected=401)
        assert call('/mensajes/no-leidos',token=b)['total']==antes+1
        for t, q in [(a,f'id_usuario={otro}&bandeja=enviados'),(b,f'id_usuario={uid}&bandeja=recibidos')]:
            assert ids[0] in [x['id_mensaje'] for x in call('/mensajes?'+q,token=t)]
        assert ids[0] not in [x['id_mensaje'] for x in call(f'/mensajes?id_usuario={uid}',token=admin)]
        conv = call('/mensajes/conversaciones',token=b)
        assert any(x['usuario']['id_usuario']==uid and x['ultimo_mensaje']['id_mensaje']==ids[0] and x['no_leidos']>=1 for x in conv)
        leido = call(ruta+'/leido','PUT',token=b)
        assert leido['leido'] and leido['fecha_lectura']
        assert call(ruta+'/leido','PUT',token=b)['fecha_lectura']==leido['fecha_lectura']
        assert call('/mensajes/no-leidos',token=b)['total']==antes
        respuesta = call('/mensajes','POST',dict(id_receptor=uid,mensaje=marca+' respuesta'),b,201)
        ids.append(respuesta['id_mensaje'])
        assert set(ids).issubset({x['id_mensaje'] for x in call(f'/mensajes?id_usuario={otro}',token=a)})
        call('/mensajes?limite=101',token=a,expected=422)
        with SessionLocal() as db:
            filas = db.scalars(select(Mensaje).where(Mensaje.id_mensaje.in_(ids))).all()
            assert len(filas)==2 and any(x.id_mensaje==ids[0] and x.leido for x in filas)
        print('OK mensajes y lectura persistidos en MySQL')
        print('PRUEBAS DE MENSAJERIA EXITOSAS')
    finally:
        try:
            with SessionLocal() as db:
                db.execute(delete(Mensaje).where(Mensaje.mensaje.in_([marca, marca+' respuesta'])))
                db.commit()
            print('OK limpieza de mensajes temporales')
        finally:
            for t in tokens:
                call('/auth/logout','POST',token=t)

if __name__ == '__main__':
    main()
