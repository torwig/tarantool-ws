box.cfg{}

s = box.schema.space.create('trades', {engine = 'vinyl', if_not_exists = true})

s:format({
    {name = 'id', type = 'unsigned'},
    {name = 'source', type = 'string'},
    {name = 'symbol', type = 'string'},
    {name = 'time',   type = 'number'},
    {name = 'qty',    type = 'number'},
    {name = 'px',     type = 'number'}                                                                                                                                                                          
    }
)

s:create_index('secondary', {
    type = 'tree',
    parts = {'id', 'source', 'symbol'}
}
)

box.schema.sequence.create('S', {if_not_exists = true})
