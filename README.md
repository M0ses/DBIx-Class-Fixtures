** IMPORTANT **

WARNING: This is *NOT* the official CPAN DBIx::Class::Fixtures modules. It`s just for discussing some of my considerations for usefull enhancements to the official module


** Current modifications **


{
   "sets" : [
      {  
         "quantity" : "all",
         "class" : "Scheduling",
         "cond" : { "state" : "PERIODIC" },
         "skip_data_visitor" : 1
         "substitute" : {
            "id" : null,
            "timestamp" : "\\UNIX_TIMESTAMP()"
         }
      },
   ],
   "skip_tmp_dir" : 1,
   "file_per_data_set" : 1,
   ""
   "might_have" : {
      "fetch" : 0
   },
   "belongs_to" : {
      "fetch" : 0
   },
   "has_many" : {
      "fetch" : 0
   }
}


