struct StorePutKey{T} <: ResourceKey
  priority :: Int
  id :: UInt
  item :: T
  StorePutKey{T}(priority, id, item) where T = new(priority, id, item)
end

struct StoreGetKey <: ResourceKey
  priority :: Int
  id :: UInt
  filter :: Function
end

mutable struct Store{T} <: AbstractResource
  env :: Environment
  capacity :: UInt
  items :: Set{T}
  seid :: UInt
  put_queue :: DataStructures.PriorityQueue{Put, StorePutKey{T}}
  get_queue :: DataStructures.PriorityQueue{Get, StoreGetKey}
  function Store{T}(env::Environment; capacity::UInt=typemax(UInt)) where {T}
    new(env, capacity, Set{T}(), zero(UInt), DataStructures.PriorityQueue{Put, StorePutKey{T}}(), DataStructures.PriorityQueue{Get, StoreGetKey}())
  end
end

function put(sto::Store{T}, item::T; priority::Int=0) where T
  put_ev = Put(sto.env)
  sto.put_queue[put_ev] = StorePutKey{T}(priority, sto.seid+=one(UInt), item)
  @callback trigger_get(put_ev, sto)
  trigger_put(put_ev, sto)
  put_ev
end

get_any_item(::T) where T = true

function get(sto::Store{T}, filter::Function=get_any_item; priority::Int=0) where T
  get_ev = Get(sto.env)
  sto.get_queue[get_ev] = StoreGetKey(priority, sto.seid+=one(UInt), filter)
  @callback trigger_put(get_ev, sto)
  trigger_get(get_ev, sto)
  get_ev
end

function do_put(sto::Store{T}, put_ev::Put, key::StorePutKey{T}) where {T}
  if length(sto.items) < sto.capacity
    push!(sto.items, key.item)
    schedule(put_ev)
  end
  false
end

function do_get(sto::Store{T}, get_ev::Get, key::StoreGetKey) where {T}
  for item in sto.items
    if key.filter(item)
      delete!(sto.items, item)
      schedule(get_ev; value=item)
      break
    end
  end
  true
end
