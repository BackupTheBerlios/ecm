#----------------------------------------------------------------------------------------------------
# File acc_permission_test.py
# Aithor: Guardini Domenico
# Input: none
# Output: A graph structure implemented in the acc database whit an
#		amount of 0-10-100-1000-10000-100000 garbage tuples separing
#                the tuples of interest
#----------------------------------------------------------------------------------------------------
# DEVELOPEMENT
#	- inserting every tuple of interest whit an appropriate name
#	- inserting a certain number of garbage tuples with automatic
#	  naming
#	- inserting the arcs to create the needed stucture
#	- testing query time with every amount of garbage tuples
#----------------------------------------------------------------------------------------------------
# IMPORTING NECESSARY MODULES
#----------------------------------------------------------------------------------------------------
import pgdb
import time as T
import string
#----------------------------------------------------------------------------------------------------
# debug>0: output on the standard device of debug informations
__DEBUG=0
#----------------------------------------------------------------------------------------------------
def db_open():
	import pgdb
	db = pgdb.connect(database='versatile',host='127.0.0.1:5432',user='postgres')
	return db
#----------------------------------------------------------------------------------------------------
def db_close(db):
	db.close()
#----------------------------------------------------------------------------------------------------
def db_cursor(db):
	return db.cursor()
#----------------------------------------------------------------------------------------------------
def insert_arc(cur,elem,child):
	sql="insert into arcs values (10,%s,%s,%s,%s)" % \
	(elem['entity_id'],elem['instance_id'],child['entity_id'],child['instance_id'])
	if __DEBUG: print sql
	cur.execute(sql)
#----------------------------------------------------------------------------------------------------
def get_parents(cur, node, depth, type):
	sql="SELECT * FROM relatives(%d, %d, 0, %d, 0, 0) AS res(entity_id integer, instance_id bigint, dist integer) WHERE entity_id=%d ORDER BY dist" %(node['entity_id'], node['instance_id'], depth, type)
	cur.execute(sql)
	result=cur.fetchall()
	return result
#----------------------------------------------------------------------------------------------------
def get_children(cur, node, depth, type):
	sql="SELECT * FROM relatives(%d, %d, 0, %d, 0, 1) AS res(entity_id integer, instance_id bigint, dist integer) WHERE entity_id=%d ORDER BY dist" %(node['entity_id'], node['instance_id'], depth, type)
	cur.execute(sql)
	result=cur.fetchall()
	return result
#----------------------------------------------------------------------------------------------------
def clear_db(cur):
	sql="DELETE FROM users WHERE id>1"
	cur.execute(sql)
	sql="DELETE FROM groups WHERE id>1"
	cur.execute(sql)
	sql="DELETE FROM items WHERE id>1"
	cur.execute(sql)
	sql="DELETE FROM permissions WHERE id>1"
	cur.execute(sql)
	sql="DELETE FROM agents"
	cur.execute(sql)
#----------------------------------------------------------------------------------------------------
def insert_groups(cur, num_garbage):
	root={}
	root['entity_id']=2
	root['instance_id']=1
	act_group={}
	act_group['entity_id']=2
	for index in range (0,num_garbage +1):
		sql="INSERT INTO groups (id, name) VALUES (10, 'GROUP %d')" %(index)
		cur.execute(sql)
		sql="SELECT instance_id FROM last_used_id WHERE entity_id = 2"
		cur.execute(sql)
		act_group['instance_id']=cur.fetchone()[0]
		insert_arc(cur,root,act_group)
#----------------------------------------------------------------------------------------------------
def insert_users(cur, num_garbage):
	root={}
	root['entity_id']=1
	root['instance_id']=1
	act_user={}
	act_user['entity_id']=1
	fat_group={}
	fat_group['entity_id']=2
	for index in range (0,num_garbage +1):
		sql="INSERT INTO users (id, name, pwd) VALUES (10, 'USER A-%d', 'PWD A-%d')" %(index,index)
		cur.execute(sql)
		sql="SELECT instance_id FROM last_used_id WHERE entity_id =1"
		cur.execute(sql)
		act_user['instance_id']=cur.fetchone()[0]
		insert_arc(cur,root,act_user)
		# finding entity_id of the father group
		sql="SELECT id FROM groups WHERE name='GROUP %d'" %(index)
		cur.execute(sql)
		fat_group['instance_id']=cur.fetchone()[0]
		#inserting the arc from the father group and the actual element
		insert_arc(cur, fat_group, act_user)
	for index in range (0, num_garbage +1):	
		sql="INSERT INTO users (id, name, pwd) VALUES (10, 'USER B-%d', 'PWD B-%d')" %(index,index)
		cur.execute(sql)
		sql="SELECT instance_id FROM last_used_id WHERE entity_id =1"
		cur.execute(sql)
		act_user['instance_id']=cur.fetchone()[0]
		sql="SELECT id FROM groups WHERE name='GROUP %d'" %(index)
		cur.execute(sql)
		fat_group['instance_id']=cur.fetchone()[0]
		insert_arc(cur,root,act_user)
		insert_arc(cur, fat_group, act_user)
#----------------------------------------------------------------------------------------------------
def insert_items(cur, num_garbage):
	root={}
	root['entity_id']=10
	root['instance_id']=1
	act_item = {}
	act_item['entity_id']=10
	fat_user={}
	fat_user['entity_id']=1
	fat_item={}
	fat_item['entity_id']=10
	for index in range(0, num_garbage +1):
		# finding the id for the father user
		sql="SELECT id FROM users WHERE name='USER A-%d'" %(index)
		cur.execute(sql)
		fat_user['instance_id']=cur.fetchone()[0]
		
		sql="INSERT INTO items (id, name) VALUES (10, 'ITEM A-%d')" %(index)
		cur.execute(sql)
		sql="SELECT instance_id FROM last_used_id WHERE entity_id =10"
		cur.execute(sql)
		act_item['instance_id']=cur.fetchone()[0]
		insert_arc(cur, root, act_item)
		insert_arc(cur,fat_user, act_item) # inserting arc for the main structure
	for index in range(0, num_garbage +1):
		# finding the id for the father user
		sql="SELECT id FROM users WHERE name='USER A-%d'" %(index)
		cur.execute(sql)
		fat_user['instance_id']=cur.fetchone()[0]
		
		sql="INSERT INTO items (id, name) VALUES (10, 'ITEM B-%d')" %(index)
		cur.execute(sql)
		sql="SELECT instance_id FROM last_used_id WHERE entity_id =10"
		cur.execute(sql)
		act_item['instance_id']=cur.fetchone()[0]
		insert_arc(cur,root,act_item)
		insert_arc(cur,fat_user, act_item) # inserting arc for the main structure
		
	for index in range(0, num_garbage +1):
		# finding the id for the father user
		sql="SELECT id FROM users WHERE name='USER A-%d'" %(index)
		cur.execute(sql)
		fat_user['instance_id']=cur.fetchone()[0]
		
		sql="INSERT INTO items (id, name) VALUES (10, 'ITEM C-%d')" %(index)
		cur.execute(sql)
		sql="SELECT instance_id FROM last_used_id WHERE entity_id =10"
		cur.execute(sql)
		act_item['instance_id']=cur.fetchone()[0]
		insert_arc(cur,root,act_item)
		insert_arc(cur,fat_user, act_item) # inserting arc for the main structure
		
	for index in range(0, num_garbage +1):
		# finding the id for the father user
		sql="SELECT id FROM users WHERE name='USER A-%d'" %(index)
		cur.execute(sql)
		fat_user['instance_id']=cur.fetchone()[0]
		
		sql="INSERT INTO items (id, name) VALUES (10, 'ITEM D-%d')" %(index)
		cur.execute(sql)
		sql="SELECT instance_id FROM last_used_id WHERE entity_id =10"
		cur.execute(sql)
		act_item['instance_id']=cur.fetchone()[0]
		insert_arc(cur,root,act_item)
		insert_arc(cur,fat_user, act_item) # inserting arc for the main structure
		
	for index in range(0, num_garbage +1):
		# finding the id for the father user
		sql="SELECT id FROM users WHERE name='USER A-%d'" %(index)
		cur.execute(sql)
		fat_user['instance_id']=cur.fetchone()[0]
		
		sql="INSERT INTO items (id, name) VALUES (10, 'ITEM E-%d')" %(index)
		cur.execute(sql)
		sql="SELECT instance_id FROM last_used_id WHERE entity_id =10"
		cur.execute(sql)
		act_item['instance_id']=cur.fetchone()[0]
		insert_arc(cur,root,act_item)
		insert_arc(cur,fat_user, act_item) # inserting arc for the main structure
		
	for index in range(0, num_garbage +1):	
		sql="SELECT id FROM users WHERE name='USER B-%d'" %(index)
		cur.execute(sql)
		fat_user['instance_id']=cur.fetchone()[0]
		
		sql="INSERT INTO items (id, name) VALUES (10, 'ITEM F-%d')" %(index)
		cur.execute(sql)
		sql="SELECT instance_id FROM last_used_id WHERE entity_id =10"
		cur.execute(sql)
		act_item['instance_id']=cur.fetchone()[0]
		insert_arc(cur,root,act_item)
		insert_arc(cur,fat_user, act_item) # inserting arc for the main structure
		
	for index in range(0, num_garbage +1):	
		sql="SELECT id FROM items WHERE name = 'ITEM A-%d'" %(index)
		cur.execute(sql)
		fat_item['instance_id']=cur.fetchone()[0]
		
		sql="INSERT INTO items (id, name) VALUES (10, 'ITEM G-%d')" %(index)
		cur.execute(sql)
		sql="SELECT instance_id FROM last_used_id WHERE entity_id =10"
		cur.execute(sql)
		act_item['instance_id']=cur.fetchone()[0]
		insert_arc(cur,root,act_item)
		insert_arc(cur, fat_item, act_item) # inserting arc for the main structure
		
	for index in range(0, num_garbage +1):	
		sql="SELECT id FROM items WHERE name = 'ITEM B-%d'" %(index)
		cur.execute(sql)
		fat_item['instance_id']=cur.fetchone()[0]
		
		sql="INSERT INTO items (id, name) VALUES (10, 'ITEM H-%d')" %(index)
		cur.execute(sql)
		sql="SELECT instance_id FROM last_used_id WHERE entity_id =10"
		cur.execute(sql)
		act_item['instance_id']=cur.fetchone()[0]
		insert_arc(cur,root,act_item)
		insert_arc(cur, fat_item, act_item) # inserting arc for the main structure
		
	for index in range(0, num_garbage +1):	
		sql="SELECT id FROM items WHERE name = 'ITEM C-%d'" %(index)
		cur.execute(sql)
		fat_item['instance_id']=cur.fetchone()[0]
		
		sql="INSERT INTO items (id, name) VALUES (10, 'ITEM I-%d')" %(index)
		cur.execute(sql)
		sql="SELECT instance_id FROM last_used_id WHERE entity_id =10"
		cur.execute(sql)
		act_item['instance_id']=cur.fetchone()[0]
		insert_arc(cur,root,act_item)
		insert_arc(cur, fat_item, act_item) # inserting arc for the main structure
		
	for index in range(0, num_garbage +1):	
		sql="SELECT id FROM items WHERE name = 'ITEM D-%d'" %(index)
		cur.execute(sql)
		fat_item['instance_id']=cur.fetchone()[0]
		
		sql="INSERT INTO items (id, name) VALUES (10, 'ITEM J-%d')" %(index)
		cur.execute(sql)
		sql="SELECT instance_id FROM last_used_id WHERE entity_id =10"
		cur.execute(sql)
		act_item['instance_id']=cur.fetchone()[0]
		insert_arc(cur,root,act_item)
		insert_arc(cur, fat_item, act_item) # inserting arc for the main structure
		
	for index in range(0, num_garbage +1):	
		sql="SELECT id FROM items WHERE name = 'ITEM E-%d'" %(index)
		cur.execute(sql)
		fat_item['instance_id']=cur.fetchone()[0]
		
		sql="INSERT INTO items (id, name) VALUES (10, 'ITEM K-%d')" %(index)
		cur.execute(sql)
		sql="SELECT instance_id FROM last_used_id WHERE entity_id =10"
		cur.execute(sql)
		act_item['instance_id']=cur.fetchone()[0]
		insert_arc(cur,root,act_item)
		insert_arc(cur, fat_item, act_item) # inserting arc for the main structure
		
	for index in range(0, num_garbage +1):	
		sql="SELECT id FROM items WHERE name = 'ITEM F-%d'" %(index)
		cur.execute(sql)
		fat_item['instance_id']=cur.fetchone()[0]
		
		sql="INSERT INTO items (id, name) VALUES (10, 'ITEM L-%d')" %(index)
		cur.execute(sql)
		sql="SELECT instance_id FROM last_used_id WHERE entity_id =10"
		cur.execute(sql)
		act_item['instance_id']=cur.fetchone()[0]
		insert_arc(cur,root,act_item)
		insert_arc(cur, fat_item, act_item) # inserting arc for the main structure
		
	for index in range(0, num_garbage +1):	
		sql="SELECT id FROM items WHERE name = 'ITEM L-%d'" %(index)
		cur.execute(sql)
		fat_item['instance_id']=cur.fetchone()[0]
		
		sql="INSERT INTO items (id, name) VALUES (10, 'ITEM M-%d')" %(index)
		cur.execute(sql)
		sql="SELECT instance_id FROM last_used_id WHERE entity_id =10"
		cur.execute(sql)
		act_item['instance_id']=cur.fetchone()[0]
		insert_arc(cur,root,act_item)
		insert_arc(cur, fat_item, act_item) # inserting arc for the main structure
		
	for index in range(0, num_garbage +1):	
		sql="SELECT id FROM items WHERE name = 'ITEM M-%d'" %(index)
		cur.execute(sql)
		fat_item['instance_id']=cur.fetchone()[0]
		
		sql="INSERT INTO items (id, name) VALUES (10, 'ITEM N-%d')" %(index)
		cur.execute(sql)
		sql="SELECT instance_id FROM last_used_id WHERE entity_id =10"
		cur.execute(sql)
		act_item['instance_id']=cur.fetchone()[0]
		insert_arc(cur,root,act_item)
		insert_arc(cur, fat_item, act_item) # inserting arc for the main structure
		
	for index in range(0, num_garbage +1):	
		sql="SELECT id FROM items WHERE name = 'ITEM N-%d'" %(index)
		cur.execute(sql)
		fat_item['instance_id']=cur.fetchone()[0]
		
		sql="INSERT INTO items (id, name) VALUES (10, 'ITEM O-%d')" %(index)
		cur.execute(sql)
		sql="SELECT instance_id FROM last_used_id WHERE entity_id =10"
		cur.execute(sql)
		act_item['instance_id']=cur.fetchone()[0]
		insert_arc(cur,root,act_item)
		insert_arc(cur, fat_item, act_item) # inserting arc for the main structure
#----------------------------------------------------------------------------------------------------
def insert_permissions(cur, num_garbage):
	#~ root={}
	#~ root['entity_id']=7
	#~ root['instance_id']=1
	act_permission={}
	act_permission['entity_id']=7
	perm_type={}
	perm_type['entity_id']=9
	for index in range(0, num_garbage +1):
		sql="INSERT INTO permissions (id, name) VALUES (10, 'PERMISSION A-%d')" %(index)
		cur.execute(sql)
		sql="SELECT instance_id FROM last_used_id WHERE entity_id=7"
		cur.execute(sql)
		act_permission['instance_id']=cur.fetchone()[0]
		sql="SELECT id FROM perm_types WHERE perm='WRITE'"
		cur.execute(sql)
		perm_type['instance_id']=cur.fetchone()[0]
		#~ insert_arc(cur,root,act_permission)
		insert_arc(cur, act_permission, perm_type) # inserting arc for the main structure
		
	for index in range(0, num_garbage +1):	
		sql="SELECT id FROM perm_types WHERE perm='READ'"
		cur.execute(sql)
		perm_type['instance_id']=cur.fetchone()[0]
		sql="INSERT INTO permissions (id, name) VALUES (10, 'PERMISSION B-%d')" %(index)
		cur.execute(sql)
		sql="SELECT instance_id FROM last_used_id WHERE entity_id=7"
		cur.execute(sql)
		act_permission['instance_id']=cur.fetchone()[0]
		#~ insert_arc(cur,root,act_permission)
		insert_arc(cur, act_permission, perm_type) # inserting arc for the main structure
		
	for index in range(0, num_garbage +1):	
		sql="SELECT id FROM perm_types WHERE perm='READ'"
		cur.execute(sql)
		perm_type['instance_id']=cur.fetchone()[0]
		sql="INSERT INTO permissions (id, name) VALUES (10, 'PERMISSION C-%d')" %(index)
		cur.execute(sql)
		sql="SELECT instance_id FROM last_used_id WHERE entity_id=7"
		cur.execute(sql)
		act_permission['instance_id']=cur.fetchone()[0]
		#~ insert_arc(cur,root,act_permission)
		insert_arc(cur, act_permission, perm_type) # inserting arc for the main structure
		
	for index in range(0, num_garbage +1):	
		sql="SELECT id FROM perm_types WHERE perm='READ'"
		cur.execute(sql)
		perm_type['instance_id']=cur.fetchone()[0]
		sql="INSERT INTO permissions (id, name) VALUES (10, 'PERMISSION D-%d')" %(index)
		cur.execute(sql)
		sql="SELECT instance_id FROM last_used_id WHERE entity_id=7"
		cur.execute(sql)
		act_permission['instance_id']=cur.fetchone()[0]
		#~ insert_arc(cur,root,act_permission)
		insert_arc(cur, act_permission, perm_type) # inserting arc for the main structure
		
#----------------------------------------------------------------------------------------------------
def insert_agents(cur, num_garbage):
	act_agent={}
	act_agent['entity_id']=8
	fat_permission={}
	fat_permission['entity_id']=7
	son_item={}
	son_item['entity_id']=10
	son_user={}
	son_user['entity_id']=1
	for index in range(0, num_garbage +1):
		sql="SELECT id FROM permissions WHERE name='PERMISSION A-%d'" %(index)
		cur.execute(sql)
		fat_permission['instance_id']=cur.fetchone()[0]
		
		sql="INSERT INTO agents (id, ag_type, ag_depth) VALUES (10, 'SUBJECT', 0)"
		cur.execute(sql)
		sql="SELECT instance_id FROM last_used_id WHERE entity_id=8"
		cur.execute(sql)
		act_agent['instance_id']=cur.fetchone()[0]
		sql="SELECT id FROM items WHERE name='ITEM I-%d'" %(index)
		cur.execute(sql)
		son_item['instance_id']=cur.fetchone()[0]
		insert_arc(cur, fat_permission, act_agent)
		insert_arc(cur, act_agent, son_item)
		
	for index in range(0, num_garbage +1):
		sql="SELECT id FROM permissions WHERE name='PERMISSION A-%d'" %(index)
		cur.execute(sql)
		fat_permission['instance_id']=cur.fetchone()[0]
		
		sql="INSERT INTO agents (id, ag_type, ag_depth) VALUES (10, 'OBJECT', -1)"#MODIFIED FOR TESTIG PURPOSE
		cur.execute(sql)
		sql="SELECT instance_id FROM last_used_id WHERE entity_id=8"
		cur.execute(sql)
		act_agent['instance_id']=cur.fetchone()[0]
		sql="SELECT id FROM items WHERE name='ITEM F-%d'" %(index)
		cur.execute(sql)
		son_item['instance_id']=cur.fetchone()[0]
		insert_arc(cur, fat_permission, act_agent)
		insert_arc(cur, act_agent, son_item)
		
	for index in range(0, num_garbage +1):
		sql="SELECT id FROM permissions WHERE name='PERMISSION B-%d'" %(index)
		cur.execute(sql)
		fat_permission['instance_id']=cur.fetchone()[0]
		
		sql="INSERT INTO agents (id, ag_type, ag_depth) VALUES (10, 'SUBJECT', -1)"
		cur.execute(sql)
		sql="SELECT instance_id FROM last_used_id WHERE entity_id=8"
		cur.execute(sql)
		act_agent['instance_id']=cur.fetchone()[0]
		sql="SELECT id FROM users WHERE name='USER A-%d'" %(index)
		cur.execute(sql)
		son_user['instance_id']=cur.fetchone()[0]
		insert_arc(cur, fat_permission, act_agent)
		insert_arc(cur, act_agent, son_user)
	
	for index in range(0, num_garbage +1):
		sql="SELECT id FROM permissions WHERE name='PERMISSION B-%d'" %(index)
		cur.execute(sql)
		fat_permission['instance_id']=cur.fetchone()[0]
		
		sql="INSERT INTO agents (id, ag_type, ag_depth) VALUES (10, 'OBJECT', -1)"
		cur.execute(sql)
		sql="SELECT instance_id FROM last_used_id WHERE entity_id=8"
		cur.execute(sql)
		act_agent['instance_id']=cur.fetchone()[0]
		sql="SELECT id FROM items WHERE name='ITEM L-%d'" %(index)
		cur.execute(sql)
		son_item['instance_id']=cur.fetchone()[0]
		insert_arc(cur, fat_permission, act_agent)
		insert_arc(cur, act_agent, son_item)
		
	for index in range(0, num_garbage +1):	
		sql="SELECT id FROM permissions WHERE name='PERMISSION C-%d'" %(index)
		cur.execute(sql)
		fat_permission['instance_id']=cur.fetchone()[0]
		
		sql="INSERT INTO agents (id, ag_type, ag_depth) VALUES (10, 'SUBJECT', 1)"
		cur.execute(sql)
		sql="SELECT instance_id FROM last_used_id WHERE entity_id=8"
		cur.execute(sql)
		act_agent['instance_id']=cur.fetchone()[0]
		sql="SELECT id FROM users WHERE name='USER A-%d'" %(index)
		cur.execute(sql)
		son_user['instance_id']=cur.fetchone()[0]
		insert_arc(cur, fat_permission, act_agent)
		insert_arc(cur, act_agent, son_user)
	
	for index in range(0, num_garbage +1):	
		sql="SELECT id FROM permissions WHERE name='PERMISSION C-%d'" %(index)
		cur.execute(sql)
		fat_permission['instance_id']=cur.fetchone()[0]
		
		sql="INSERT INTO agents (id, ag_type, ag_depth) VALUES (10, 'OBJECT', 2)"
		cur.execute(sql)
		sql="SELECT instance_id FROM last_used_id WHERE entity_id=8"
		cur.execute(sql)
		act_agent['instance_id']=cur.fetchone()[0]
		sql="SELECT id FROM users WHERE name='USER B-%d'" %(index)
		cur.execute(sql)
		son_user['instance_id']=cur.fetchone()[0]
		insert_arc(cur, fat_permission, act_agent)
		insert_arc(cur, act_agent, son_user)
		
	for index in range(0, num_garbage +1):
		sql="SELECT id FROM permissions WHERE name='PERMISSION D-%d'" %(index)
		cur.execute(sql)
		fat_permission['instance_id']=cur.fetchone()[0]
		
		sql="INSERT INTO agents (id, ag_type, ag_depth) VALUES (10, 'SUBJECT', 0)"
		cur.execute(sql)
		sql="SELECT instance_id FROM last_used_id WHERE entity_id=8"
		cur.execute(sql)
		act_agent['instance_id']=cur.fetchone()[0]
		sql="SELECT id FROM items WHERE name='ITEM L-%d'" %(index)
		cur.execute(sql)
		son_item['instance_id']=cur.fetchone()[0]
		insert_arc(cur, fat_permission, act_agent)
		insert_arc(cur, act_agent, son_item)
		
	for index in range(0, num_garbage +1):
		sql="SELECT id FROM permissions WHERE name='PERMISSION D-%d'" %(index)
		cur.execute(sql)
		fat_permission['instance_id']=cur.fetchone()[0]
		
		sql="INSERT INTO agents (id, ag_type, ag_depth) VALUES (10, 'OBJECT', 0)"
		cur.execute(sql)
		sql="SELECT instance_id FROM last_used_id WHERE entity_id=8"
		cur.execute(sql)
		act_agent['instance_id']=cur.fetchone()[0]
		sql="SELECT id FROM items WHERE name='ITEM I-%d'" %(index)
		cur.execute(sql)
		son_item['instance_id']=cur.fetchone()[0]
		insert_arc(cur, fat_permission, act_agent)
		insert_arc(cur, act_agent, son_item)
#----------------------------------------------------------------------------------------------------
def get_single_child(cur, start_node, end_node, depth):
	if not depth == -1:	depth = depth +1
	sql="SELECT * FROM relatives(%d, %d, 0, %d, 0, 1) AS res(entity_id integer, instance_id bigint, dist integer) WHERE entity_id=%d AND instance_id = %d ORDER BY dist" %(start_node['entity_id'], start_node['instance_id'], depth, end_node['entity_id'], end_node['instance_id'] )
	cur.execute(sql)
	try:
		result=cur.fetchone()[2]
		return result
	except:
		return
#----------------------------------------------------------------------------------------------------
def find_permission(cur, num_garbage):
	agent_item={}
	agent_item['entity_id']=8
	
	perm_item={}
	perm_item['entity_id']=7
	
	valid_subj_perm=[]
	valid_obj_perm=[]
	
	subject_item={}
	subject_item['entity_id']=10
	sql="SELECT id FROM items WHERE name='ITEM I-%d'" %(num_garbage)
	cur.execute(sql)
	subject_item['instance_id']=cur.fetchone()[0]
	
	object_item={}
	object_item['entity_id']=10
	sql="SELECT id FROM items WHERE name='ITEM O-%d'" %(num_garbage)
	cur.execute(sql)
	object_item['instance_id']=cur.fetchone()[0]
	
	permissions=get_parents(cur, subject_item, -1, 7)
	if __DEBUG: print permissions
	for p in permissions:
		perm_item['instance_id']=p[1]
		agents=get_children(cur, perm_item, 1,8)
		for ag in agents:
			sql="SELECT * FROM agents WHERE id=%d" %(ag[1])
			cur.execute(sql)
			age=cur.fetchone()
			if __DEBUG: print age
			if age[2]=='SUBJECT':
				agent_item['instance_id']=age[1]
				g=get_single_child(cur, agent_item, subject_item, age[3])
				if __DEBUG: print g
				if not g is None:	
					valid_subj_perm.append(p)
	if __DEBUG: print valid_subj_perm
	for p in valid_subj_perm:
		perm_item['instance_id']=p[1]
		agents=get_children(cur, perm_item, 1,8)
		for ag in agents:
			sql="SELECT * FROM agents WHERE id=%d" %(ag[1])
			cur.execute(sql)
			age=cur.fetchone()
			if __DEBUG: print age
			if age[2]=='OBJECT':
				agent_item['instance_id']=age[1]
				g=get_single_child(cur, agent_item, object_item, age[3])
				if __DEBUG: print g
				if not g is None:	
					p.append(g)
					valid_obj_perm.append(p)
	if __DEBUG: print valid_obj_perm
	applicable=[]
	try: applicable.append(valid_obj_perm.pop())
	except: 
		if __DEBUG: print "ITEM I-%d has no permission upon ITEM O-%d!" %(num_garbage,num_garbage)
		return
	for p in valid_obj_perm:
		if p[2] < applicable[0][2]:
			applicable=[]
			applicable.append(p)
		elif p[2] == applicable[0][2]:
			applicable.append(p)
	if __DEBUG: print applicable
	applied=[]
	applied.append(applicable.pop())
	for p in applicable:
		if p[3] < applied[0][3]:
			applied=[].append(p)
		elif p[3] == applied[0][3]:
			applied.append(p)
	if __DEBUG: print applied
	types=[]
	for p in applied:
		perm_item['instance_id']=p[1]
		p_l=get_children(cur, perm_item, -1, 9)
		if __DEBUG:print p_l
		for p_ll in p_l:
			sql="SELECT perm FROM perm_types WHERE id=%d" %(p_ll[1])
			cur.execute(sql)
			types.append(cur.fetchone()[0])
	if __DEBUG:
		print "ITEM I-%d has UPON ITEM O-%d the following permissions" %(num_garbage,num_garbage)
		for t in types: print t
#----------------------------------------------------------------------------------------------------
# MAIN
#----------------------------------------------------------------------------------------------------
if __name__=='__main__':
	__CRAZY__ = 0
	if __CRAZY__: 
		passo=[1, 10, 100, 1000, 10000]
		print "\nSTARTED IN CRAZY MODE!!!!\n"
	else: passo = [1]
	conn = db_open()
	cur = db_cursor(conn)
	print "Number of garbage elements = 0"
	start=T.time()
	clear_db(cur)
	stop=T.time()
	print "Deletion time = %f" %(stop-start)
	start=T.time()
	insert_groups(cur, 0)
	insert_users(cur, 0)
	insert_items(cur, 0)
	insert_permissions(cur, 0)
	insert_agents(cur, 0)
	stop=T.time()
	conn.commit()
	print "Insertion time = %f" %(stop - start)
	print "Average insertion time per element = %f" %((stop-start)/85)
	start=T.time()
	find_permission(cur, 0)
	stop=T.time()
	print "Query time = %f\n" %(stop-start)
	for p in passo:
		for index in range(1,10):
			print "Number of garbage elements = %d" %(p*index)
			start=T.time()
			clear_db(cur)
			stop=T.time()
			print "Deletion time = %f" %(stop-start)
			#~ clear_db(cur)
			start=T.time()
			insert_groups(cur, p*index)
			insert_users(cur, p*index)
			insert_items(cur, p*index)
			insert_permissions(cur, p*index)
			insert_agents(cur, p*index)
			stop=T.time()
			conn.commit()
			print "Insertion time = %f" %(stop - start)
			print "Average insertion time per element = %f" %((stop-start)/(85+p*index*85))
			start=T.time()
			find_permission(cur, p*index)
			stop=T.time()
			print "Query time = %f\n" %(stop-start)
	if __CRAZY__:
		print "Number of garbage elements = 100000"
		start=T.time()
		clear_db(cur)
		stop=T.time()
		print "Deletion time = %f" %(stop-start)
		#~ clear_db(cur)
		start=T.time()
		insert_groups(cur, 100000)
		insert_users(cur, 100000)
		insert_items(cur, 100000)
		insert_permissions(cur, 100000)
		insert_agents(cur, 100000)
		stop=T.time()
		conn.commit()
		print "Insertion time = %f" %(stop - start) 
		print "Average insertion time per element = %f" %((stop-start)/8500085)
		start=T.time()
		find_permission(cur, 100000)
		stop=T.time()
		print "Query time = %f\n" %(stop-start)
		print "THANKS BE TO GOD!!!"