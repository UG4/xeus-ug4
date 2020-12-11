/***********************************************************************************                                                               
* Copyright (c) 2020, Goethe University Frankfurt, G-CSC                           *                                                               
* Author: Arne Naegel                                                              *                                                               
*                                                                                  *                                                               
* Distributed under the terms of the BSD 3-Clause License.                         *                                                               
*                                                                                  *                                                               
* The full license is in the file LICENSE, distributed with this software.         *                                                               
************************************************************************************/
#include <iostream>
#include "custom_interpreter.hpp"


#include "ug.h"
#include "bindings/lua/lua_util.h"
#include "bridge/bridge.h"

#include "common/util/parameter_parsing.h"
#include "common/util/file_util.h"
#include "common/profiler/memtracker.h"
#include "common/util/os_info.h"
#include "common/util/path_provider.h"
#include "common/profiler/profile_node.h"

void ugshell_print_header();
void ug_init_path(char **, bool&);
void ug_init_bridge(bool&);
void ug_init_plugins(bool&);
void ug_check_registry(bool&);
void ug_init_luashell(int, char**);

namespace ug
{
/// Init.
   void xeus_interpreter::configure_impl()
   {
    // Perform some operations
   	std::cerr << "xeus_interpreter::configure_impl" << std::endl;

   	// Redirect std::cout with backup
   	m_cout_buff = std::cout.rdbuf();
   	std::cout.rdbuf(m_out.rdbuf());

   	// Init from ugshell_main.
   	char *argv = (char*) "\0";

   	bool errorOccurred = false;
   	int ret = 0;

   	// INIT PATH
   	ug_init_path(&argv, errorOccurred);

   	//	INIT STANDARD BRIDGE
   	ug_init_bridge(errorOccurred);

   	//	INIT PLUGINS
   	ug_init_plugins(errorOccurred);

   	if(!errorOccurred)
   	{
   			ug_check_registry(errorOccurred);
   	}

   	ug_init_luashell(0, &argv);

   	//! Register interpreter
   	if (xeus::register_interpreter(static_cast<xeus::xinterpreter*>(this)))
   	{
   		std::cerr << "Registered interpreter!" << std::endl;
   	}
   	else
   	{
   		std::cerr << "FAILED: interpreter!" << std::endl;
   	}
   }

	/// Forward request to Lua
    nl::json xeus_interpreter::execute_request_impl(int execution_counter, // Typically the cell number
                                                      const std::string& code, // Code to execute
                                                      bool silent,
                                                      bool store_history,
                                                      nl::json user_expressions,
                                                      bool /*allow_stdin*/)
    {
        // You can use the C-API of your target language for executing the code,
        // e.g. `PyRun_String` for the Python C-API
        //      `luaL_dostring` for the Lua C-API

        // Use this method for publishing the execution result to the client,
        // this method takes the ``execution_counter`` as first argument,
        // the data to publish (mime type data) as second argument and metadata
        // as third argument.
        // Replace "Hello World !!" by what you want to be displayed under the execution cell
    	nl::json jresult;  // return value


        bool errorOccurred=false;
        static const char* errSymb = " % ";

        // Error handling
        std::string ename;
        std::string evalue;
        std::vector<std::string> etraceback;

        try{
        	// Try to execute code.
        	script::ParseAndExecuteBuffer(code.c_str());
        }
        catch(SoftAbort& err){
        	// SoftAbort
        	UG_LOG("Execution of script-buffer aborted with the following message:\n")
        	UG_LOG(err.get_msg() << std::endl);

        	ename = "SoftAbort";

        }
        catch(script::LuaError& err)
        {
        	// LUA error
        	PathProvider::clear_current_path_stack();
        	if(err.show_msg())
        	{
        				if(!err.get_msg().empty()){
        					UG_LOG("LUA-ERROR: \n");
        					for(size_t i=0;i<err.num_msg();++i)
        						UG_LOG(err.get_msg(i)<<std::endl);
        				}
        	}
        	UG_LOG(errSymb<<"ABORTING script parsing.\n");
        	//quit_all_mpi_procs_in_parallel();

        	ename = "LUA-ERROR";
        	//evalue = err.what();
        	 evalue = "---";

        	errorOccurred=true;
        }
        catch(UGError &err)
        {
        	// UG error
        	PathProvider::clear_current_path_stack();

        	publish_execution_error("TypeError", "123", {"!@#$", "*(*"});

        	UG_LOG("UGError:\n");
        	for(size_t i=0; i<err.num_msg(); i++)
        	{
        			UG_LOG(err.get_file(i) << ":" << err.get_line(i) << " : " << err.get_msg(i));
        	}
        	UG_LOG("\n");
        	UG_LOG(errSymb<<"ABORTING script parsing.\n");

        	//	quit_all_mpi_procs_in_parallel();

        	ename = "UGError";
        	// evalue = err.what();
        	evalue = "---";
        	errorOccurred=true;

        }
        catch (...)
        {
        	//UG_LOG("UNKNWOWN ERROR!\n");
        	ename = "Unknown error";
            evalue = "---";

        	errorOccurred=true;
        }




        if (errorOccurred)
        {
        	jresult["status"] = "error";
        	jresult["ename"] = ename;
        	jresult["evalue"] = evalue;

        	std::vector<std::string> traceback({ename + ": " + evalue});
        	publish_execution_error(ename, evalue, traceback);
        	 jresult["status"] = "error";
        } else
        {
        	 jresult["status"] = "ok";
        	 jresult["payload"] = nl::json::array();
        	 jresult["user_expressions"] = nl::json::object();
        }

        // mime_data["text/plain"] = "Hello World !!" << code;
        // mime_data["text/plain"] = code;
        nl::json mime_data;
        mime_data["text/plain"] = m_out.str();
        m_out.str(std::string()); // reset

        publish_execution_result(execution_counter, std::move(mime_data), nl::json::object());

        // You can also use this method for publishing errors to the client, if the code
        // failed to execute
        // publish_execution_error(error_name, error_value, error_traceback);


       // jresult["status"] = errorOccurred  ? "error" : "ok"; // "abort"
        return jresult;
    }



    nl::json xeus_interpreter::complete_request_impl(const std::string& code,
                                                       int cursor_pos)
    {
        nl::json result;

        // Code starts with 'H', it could be the following completion
        if (code[0] == 'H')
        {
            result["status"] = "ok";
            result["matches"] = {"Hello", "Hey", "Howdy"};
            result["cursor_start"] = 5;
            result["cursor_end"] = cursor_pos;
        }
        // No completion result
        else
        {
            result["status"] = "ok";
            result["matches"] = {};
            result["cursor_start"] = cursor_pos;
            result["cursor_end"] = cursor_pos;
        }

        return result;
    }

    /// TODO: adjust
    nl::json xeus_interpreter::inspect_request_impl(const std::string& code,
                                                      int /*cursor_pos*/,
                                                      int /*detail_level*/)
    {
        nl::json result;

        if (code.compare("print") == 0)
        {
            result["found"] = true;
            result["text/plain"] = "Print objects to the text stream file, [...]";
        }
        else
        {
            result["found"] = false;
        }

        result["status"] = "ok";
        return result;
    }

    /// TODO: adjust
    nl::json xeus_interpreter::is_complete_request_impl(const std::string& code)
    {
        nl::json result;

        // if (is_complete(code))
        // {
            result["status"] = "complete";
        // }
        // else
        // {
        //    result["status"] = "incomplete";
        //    result["indent"] = 4;
        //}

        return result;
    }

    /// TODO: adjust for lua
    nl::json xeus_interpreter::kernel_info_request_impl()
    {
        nl::json result;
        result["implementation"] = "UG4 Kernel";
        result["implementation_version"] = "0.1.0";

        std::string banner =  " Implementation of UG4-LUA-kernel using Xeus";
        result["banner"] = banner;

        result["language_info"]["name"] = "lua";
        result["language_info"]["version"] = "1.0";
        result["language_info"]["mimetype"] = "text/x-lua";
        result["language_info"]["codemirror_mode"] = "text/x-lua";
        result["language_info"]["file_extension"] = ".lua";

        result["status"] = "ok";
        return result;
    }

    // Close kernel
    void xeus_interpreter::shutdown_request_impl() {

    	 // reset cout
    	std::cout.rdbuf(m_cout_buff);


    	// finalize
    	std::cout << "UGFinalize()" << std::endl;
    	UGFinalize();

    }

   /*
    *
    *
     void xeus_interpreter::redirect_output()
    {
    	// Redirect std::cout with backup
    	m_cout_buff = std::cout.rdbuf();
    	std::cout.rdbuf(m_out.rdbuf());
    }

    void xeus_interpreter::restore_output()
    {
    	std::cout.rdbuf(m_cout_buff);
    }
*/
    void xeus_interpreter::redirect_output()
       {
          //  p_cout_strbuf = std::cout.rdbuf();
          // p_cerr_strbuf = std::cerr.rdbuf();

           //std::cout.rdbuf(&m_cout_buffer);
           //std::cerr.rdbuf(&m_cerr_buffer);

       }

       void xeus_interpreter::restore_output()
       {
          // std::cout.rdbuf(p_cout_strbuf);
          // std::cerr.rdbuf(p_cerr_strbuf);

           // No need to remove the injected versions of [f]printf: As they forward
           // to std::cout and std::cerr, these are handled implicitly.
       }
}



