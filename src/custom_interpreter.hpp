/***********************************************************************************
* Copyright (c) 2020, Goethe University Frankfurt, G-CSC                           *
* Author: Arne Naegel                                                              *
*                                                                                  *
* Distributed under the terms of the BSD 3-Clause License.                         *
*                                                                                  *
* The full license is in the file LICENSE, distributed with this software.         *
************************************************************************************/

#ifndef CUSTOM_INTERPRETER
#define CUSTOM_INTERPRETER

#include "xeus/xinterpreter.hpp"

#include "nlohmann/json.hpp"

using xeus::xinterpreter;

namespace nl = nlohmann;

namespace ug
{


    class xeus_interpreter : public xinterpreter
    {

    public:

    	xeus_interpreter() //= default;
    	: xinterpreter(), m_out(), m_cout_buff(NULL)
    	{
    		  redirect_output();
    	}

        virtual ~xeus_interpreter() {
        	 restore_output();
        }

    private:

        void configure_impl() override;

        nl::json execute_request_impl(int execution_counter,
                                      const std::string& code,
                                      bool silent,
                                      bool store_history,
                                      nl::json user_expressions,
                                      bool allow_stdin) override;

        nl::json complete_request_impl(const std::string& code,
                                       int cursor_pos) override;

        nl::json inspect_request_impl(const std::string& code,
                                      int cursor_pos,
                                      int detail_level) override;

        nl::json is_complete_request_impl(const std::string& code) override;

        nl::json kernel_info_request_impl() override;

        void shutdown_request_impl() override;

        void redirect_output();
        void restore_output();


        std::ostringstream m_out;
        std::basic_streambuf<char, std::char_traits<char> > *m_cout_buff;
    };
}

#endif
