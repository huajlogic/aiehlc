/******************************************************************************
* Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/

#include "../../include/gcommon.h"
#include "clang/AST/ASTConsumer.h"
#include "clang/AST/Decl.h"
#include "clang/AST/RecursiveASTVisitor.h"
#include "clang/Frontend/CompilerInstance.h"
#include "clang/Frontend/FrontendAction.h"
#include "clang/Lex/Pragma.h"
#include "clang/Rewrite/Core/Rewriter.h"
#include "clang/Tooling/CommonOptionsParser.h"
#include "clang/Tooling/Tooling.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/raw_ostream.h"

//#include "AieFrontEnd.h"
#include "../mlir/mlirfront/AieFrontEnd.h"
#include <boost/algorithm/string.hpp>

#include <ios>
#include <iostream>
#include <fstream>
#include <ostream>
#include <sstream>
#include <cstdlib>
#include <regex>
#include <unordered_map>

#include "tilinglinalg_pipeline.h"

class AieFrontEnd;

static bool use_llvm_aie = false;
static bool isTilingLinalgMode = false;
static int tilingMeshRows = 0, tilingMeshCols = 0;

struct ParsedTensorInfo {
    std::string varName;
    std::vector<int64_t> shape;
    int elementBitWidth;
    bool isInput;
};
static std::vector<ParsedTensorInfo> parsedTensors;

static int parsedDebugLevel = -1; // -1 = not set by user, >=0 = #pragma aie_debug_level value
static std::vector<std::string> kernel_name_list;
static std::unordered_map<std::string, const clang::FunctionDecl*> globalKernelFuncs;
static std::string userKernelBody;      // raw source text of __global__ function body
static std::string userKernelFuncName;  // kernel function name from __global__

using namespace clang;
using namespace clang::tooling;
class GlobalFunctionVisitor : public RecursiveASTVisitor<GlobalFunctionVisitor> {
private:
	std::string GetFuncText(FunctionDecl *f) {
		clang::SourceRange functionRange = f->getSourceRange();
		clang::SourceLocation startLocation = functionRange.getBegin();
		clang::SourceLocation endLocation = Rewrite->getSourceMgr().getExpansionLoc(functionRange.getEnd());
		clang::SourceLocation endLocationWithOffset = clang::Lexer::getLocForEndOfToken(endLocation, 0, Rewrite->getSourceMgr(), Rewrite->getLangOpts());
		bool InvalidTemp = false;
		std::string fullkernel;
		clang::StringRef text = Rewrite->getSourceMgr().getBufferData(Rewrite->getSourceMgr().getFileID(startLocation), &InvalidTemp);
		if (!InvalidTemp) {
			const char* begin = text.begin() + Rewrite->getSourceMgr().getFileOffset(startLocation);
			const char* end = text.begin() + Rewrite->getSourceMgr().getFileOffset(endLocationWithOffset);
			std::string functionString(begin, end);
			fullkernel = functionString;
		} else {
			std::cerr << "Error: Unable to access the buffer for the original function text.\n";
			return "";
		}
		std::string str(fullkernel.data(), fullkernel.size());
		return str;
	}
	void ReplaceKernel(FunctionDecl *f) {
		return;
	}
public:
    explicit GlobalFunctionVisitor(Rewriter* Rewrite, ASTContext *Context, AieFrontEnd* Aiefrontend)
        : Context(Context), Rewrite(Rewrite) , Aiefrontend(Aiefrontend){
			 std::ofstream kl(AOUT+std::string("kernel_list"), std::ios::out);
		}

     void ExportFunction(FunctionDecl *FD, std::string kname) {
	     /*
        if (FD->hasBody()) {
            llvm::outs() << FD->getNameAsString() << " Function Body:\n";
            FD->getBody()->printPretty(llvm::outs(), nullptr, PrintingPolicy(Context->getLangOpts()));
            llvm::outs() << "\n\n";
        }*/
			llvm::outs() << "Exporting File: " << AOUT+std::string("kernel_list") << "\n\n";
			 std::ofstream kl(AOUT+std::string("kernel_list"), std::ios::app | std::ios::out);
			 kl << kname << std::endl;
			 kl.close();

			 std::error_code error_code;
			 //change the ext from .c into .cc to fix the aiecompiler compile issue
			llvm::outs() << "Exporting File: " << AOUT+kname + ".cc" << "\n";
			 std::ofstream fd(AOUT+kname + ".cc");
			 auto str = GetFuncText(FD);
			 //std::string toRemove = "__attribute__((annotate(\"__global__\")))";
			//fixme, shoud only remove mem_address and global annotate attribute, correct way is to do
      // one more pass to remove the related attribute
			 std::string toRemove = "__attribute__";
			 size_t pos, prepos=std::string::npos;
			 while((pos = str.find(toRemove)) != std::string::npos){
         //avoid infinite loop
				 if (prepos != std::string::npos && prepos == pos) break;
				 prepos = pos;
         //the remove logic
				 auto nstr = str.substr(pos + toRemove.size());
				 auto npos = nstr.find("(");
				 if (npos == std::string::npos) break;
				 auto cstr = nstr.c_str();
				 int lb = 1;
				 while(lb && npos < nstr.size()) {
					 auto c = cstr[++npos];
					 lb += (c == '(' ? 1 :(c == ')' ? -1 : 0) );
					 //std::cout << "npos is " << npos << " "<<lb << " is lb cstr is " << &cstr[npos]<< std::endl;
				 }
				 str.erase(pos, toRemove.size() + npos + 1);
				 //avoid infinite loop, reset prepos
				 prepos = std::string::npos;
			 }

             // Remove #ifdef KERNEL_COMPILE and #endif guards added during preprocessing
             std::string ifdefToRemove = "#ifdef KERNEL_COMPILE";
             while ((pos = str.find(ifdefToRemove)) != std::string::npos) {
                 // Find the end of line after #ifdef KERNEL_COMPILE
                 auto endOfLine = str.find("\n", pos);
                 if (endOfLine != std::string::npos) {
                     str.erase(pos, endOfLine - pos + 1);
                 } else {
                     str.erase(pos, ifdefToRemove.size());
                 }
             }
             std::string endifToRemove = "#endif";
             while ((pos = str.find(endifToRemove)) != std::string::npos) {
                 // Find the end of line after #endif
                 auto endOfLine = str.find("\n", pos);
                 if (endOfLine != std::string::npos) {
                     str.erase(pos, endOfLine - pos + 1);
                 } else {
                     str.erase(pos, endifToRemove.size());
                 }
             }

             // Capture cleaned kernel body for tiling mode computekernel.cc emission
             userKernelFuncName = kname;
             userKernelBody = str;
             llvm::outs() << "[TilingLinalg] Captured __global__ kernel body for: " << kname << "\n";

             std::string header = "/******************************************************************************"
                                  "\n* Auto-generated by aiehlc.\n"
                                  "******************************************************************************/\n";
             // llvm aie can not handle these headers yet, results in compile errors
			 if(use_llvm_aie) {
				header += 
				 "\n#include <adf.h>\n\n"
				//  "\n#include <aie_api/aie.hpp>\n"
				//  "\n#include <aie_api/aie_adf.hpp>\n"
				//  "\n#include <aie_api/utils.hpp>\n\n";
				;
			 }
			 else {
				header += 
				 "\n#include <adf.h>"
				 "\n#include <aie_api/aie.hpp>"
				 "\n#include <aie_api/aie_adf.hpp>"
				 "\n#include <aie_api/utils.hpp>\n\n";
			 }
             str = header + str;
			 fd << str << std::endl;
    }

		 void printSourceRange(const clang::SourceRange &range, const clang::SourceManager &sourceManager) {
			 llvm::outs() << "SourceRange: ";

			 // Get the start and end locations
			 clang::SourceLocation startLoc = range.getBegin();
			 clang::SourceLocation endLoc = range.getEnd();

			 // Print the file name
			 auto& sc = Rewrite->getSourceMgr();
			 llvm::outs() << sourceManager.getFilename(startLoc).str() << ":";
			 llvm::outs() << sourceManager.getFilename(endLoc).str() << ":";

			 ///*
			 // Print the start line and column
			 llvm::outs() << sourceManager.getSpellingLineNumber(startLoc) << ":" << sourceManager.getSpellingColumnNumber(startLoc) << "-";

			 // Print the end line and column
			 llvm::outs() << sourceManager.getSpellingColumnNumber(endLoc) << ":" << sourceManager.getSpellingColumnNumber(endLoc) << "\n";
			 //*/
		 }
		 bool VisitFunctionDecl(FunctionDecl *f) {
			 if (f->hasBody() && f->hasAttr<AnnotateAttr>()) {
                 // Check for streaming annotation
                 bool isStreamingKernel = false;
                 for (auto attr : f->attrs()) {
                     if (auto anno = clang::dyn_cast<clang::AnnotateAttr>(attr)) {
                         if (anno->getAnnotation() == "streaming") {
                             isStreamingKernel = true;
                             llvm::outs() << "Detected streaming kernel annotation\n";
                             break;
                         }
                     }
                 }

                for (auto attr:f->attrs()) {
					if (auto anno = clang::dyn_cast<clang::AnnotateAttr>(attr)){
						if (anno->getAnnotation() == "__global__" || anno->getAnnotation() == "__kernel__") {
							std::string kernelName = f->getNameInfo().getName().getAsString();

							// Store function decl for later tensor parameter extraction
							globalKernelFuncs[kernelName] = f;

							// std::cout << "find global " << f->getNameInfo().getName().getAsString() << std::endl;
							ParmVarDecl *param = f->getParamDecl(0);
							// llvm::outs() << "param->hasAttrs() is " << param->hasAttrs() << "\n";
							//llvm::outs << "range is " << range <<"\n";
							ExportFunction(f, kernelName);
							clang::SourceRange functionRange = f->getSourceRange();
							clang::SourceLocation startLocation = functionRange.getBegin();

							clang::SourceLocation lineStart = Rewrite->getSourceMgr().translateLineCol(
							Rewrite->getSourceMgr().getFileID(startLocation), 
							Rewrite->getSourceMgr().getSpellingLineNumber(startLocation), 1);
							Rewrite->RemoveText(f->getSourceRange());
                            // do other rewrite logic only after the RemoveText work done
                            // Pass streaming flag to frontend
                            Aiefrontend->createKernelDefinitionOp(f, Rewrite, lineStart, isStreamingKernel);
                            if (anno->getAnnotation() == "__global__") {
								std::string globalVars =
									"\n// Global variables for kernel: " + kernelName + "\n" +
									"extern unsigned char _binary_kernel_" + kernelName + "_start[];\n" +
									"extern unsigned char _binary_kernel_" + kernelName + "_end[];\n" +
									"extern unsigned int _binary_kernel_" + kernelName + "_size;\n\n";
								Rewrite->InsertText(lineStart, globalVars, true, true);
							} else if(anno->getAnnotation() == "__kernel__") {
                                // _start is declared in the generated template function; no additional globals needed here.
                            }
						} else {
							std::cerr << "not global func" << std::endl;
						}
						auto range = f->getSourceRange();
						auto& sc = Rewrite->getSourceMgr();
						// std::cout << "range.isValid() " << range.isValid() <<std::endl;
						// printSourceRange(range,  sc);
					}
					for (unsigned int i = 0; i < f->getNumParams(); ++i) {
						ParmVarDecl *param = f->getParamDecl(i);
						// llvm::outs() << "  Param " << (i + 1) << ": type: "
						// 	<< param->getType().getAsString() << "  name:"
						// 	<< param->getNameAsString() << "\n";
					}
				}
			}
			Stmt *body = f->getBody();
			TraverseStmt(body);

			 //PrintCode();
			 // This involves manipulating the AST node of the function
			 return true;
		 }
		 std::string GetCallExprString(const CallExpr *  CE) {
			 std::ostringstream ostr;
			 const FunctionDecl *Callee = CE->getDirectCallee();
			 if (Callee) {
				 ostr << Callee->getNameAsString() << "(";
				 
				 //const Expr *thirdArgExpr = CE->getArg(2)->IgnoreImpCasts();
				 //std::string functionName = "";
				 //if (const clang::StringLiteral *strLit = clang::dyn_cast<clang::StringLiteral>(thirdArgExpr)) {
					// functionName = strLit->getString().str();
					 // Use 'functionName' as needed...
				//	 std::cout<< "load kernel functionName " << functionName << std::endl; 
				 //}
				 auto num = CE->getNumArgs();			
				 for (unsigned i = 0; i < num; i++) {
					 const clang::Expr* arg = CE->getArg(i);
					 clang::QualType argType = arg->getType();
					//  std::cout << "x- Parameter " << i << " type: ";
					//  std::cout << argType.getAsString();
					//  std::cout << std::endl;
					 if (auto *DRE = dyn_cast<DeclRefExpr>(arg->IgnoreImpCasts())) {
						 if (const VarDecl *VD = dyn_cast<const VarDecl>(DRE->getDecl())) {
							 ostr << VD->getNameAsString() ;
							 ostr << ((i<num-1) ? ",":" ");
						 }
					 } else if (auto *CallAsArg = dyn_cast<CallExpr>(arg)) {
							 ostr << GetCallExprString(CallAsArg);
							 ostr << ((i<num-1) ?",":" ");
					 } else if(const clang::PointerType *ptrType = argType->getAs<clang::PointerType>()) {
						 // Check if the pointee type is char (indicating char* or const char*)
						 clang::QualType pointeeType = ptrType->getPointeeType();
						 if (pointeeType->isCharType()) {
							 std::string argStr;
							 llvm::raw_string_ostream os(argStr);
							 arg->printPretty(os, nullptr, PrintingPolicy(LangOptions()));
							//  llvm::outs() << "Pretty printed argument " << i << ": " << os.str() << "\n";
							 ostr<< os.str() <<((i<num-1) ? ",":" ");
							 /*
							 if (const DeclRefExpr *declRef = dyn_cast<const DeclRefExpr>(arg->IgnoreParenImpCasts())) {
								 const ValueDecl *valueDecl = declRef->getDecl();

								 // Get the name of the function or variable
								 std::string paramName = valueDecl->getNameAsString();
								 llvm::outs() << "Pointer parameter name: " << paramName << "\n";
							 }
							 // Evaluate the expression
							 //clang::Expr::EvalResult evalResult;
							 //if (arg->EvaluateAsRValue(evalResult, *Context)) {
							 ///	clang::APValue value = evalResult.Val;
								//auto str = clang::dyn_cast<clang::StringLiteral>(CE->getArg(i)->IgnoreImpCasts());
							  //ostr << str->getString().str() << ((i<num-1) ? ",":" ");
							 //char* charArray = const_cast<char*>(value.getCharPtr().getPointer());
							 //	std::cout << " it is string " << str->getString().str() << " " << value.getCharPtr().getPointer() << std::endl;*/
							 }
						} else if (const CStyleCastExpr *castExpr = dyn_cast<const CStyleCastExpr>(arg)) {
								 // Get the expression being cast
								 const Expr *subExpr = castExpr->getSubExpr();

								 // Check if it's a reference to a variable
								 if (const DeclRefExpr *declRef = dyn_cast<const DeclRefExpr>(subExpr)) {
									 // Get the variable declaration
									 const ValueDecl *valueDecl = declRef->getDecl();

									 // Retrieve and print the name of the variable
									//  llvm::outs() << "Variable name: " << valueDecl->getName() << "\n";
									 ostr<< valueDecl->getName().str() <<((i < num -1) ?",":" ");
								 }
						} else if (argType->isIntegerType()) {
						 clang::Expr::EvalResult xResult;
						 if (arg->EvaluateAsInt(xResult, Callee->getASTContext())) {
							 int v = xResult.Val.getInt().getExtValue();
							 ostr << v ;
							 ostr<< ((i < num -1) ?",":" ");
						 }
					 }else {
						std::string argStr;
						llvm::raw_string_ostream os(argStr);
						arg->printPretty(os, nullptr, PrintingPolicy(LangOptions()));
						ostr << os.str() << ((i < num - 1) ? "," : " ");
					 }
				 }
			 }

			 ostr<< ")";
			 return ostr.str();
		}
		 //*/

		 bool VisitCallExpr(const CallExpr * 	CE) {
			const FunctionDecl *Callee = CE->getDirectCallee();

			// Detect __aie_launch("kernelName", mesh, A, B, C, M, N, K) for tiling mode
			if (Callee && Callee->getNameAsString() == "__aie_launch") {
				isTilingLinalgMode = true;
				// Guard: only parse tensor params once (AST visitor may visit the call twice)
				if (!parsedTensors.empty()) {
					return true;
				}
				// Arg 0: kernel name (string literal after preprocessing)
				if (CE->getNumArgs() >= 2) {
					// Try to extract kernel name from first arg (string literal)
					if (const auto *SL = dyn_cast<clang::StringLiteral>(CE->getArg(0)->IgnoreParenImpCasts())) {
						llvm::outs() << "[TilingLinalg] Detected kernel launch: " << SL->getString() << "\n";
					}
					// Arg 1: aieDim mesh variable — extract rows/cols from CXXConstructExpr
					const Expr *meshArg = CE->getArg(1)->IgnoreParenImpCasts();
					if (const auto *Construct = dyn_cast<CXXConstructExpr>(meshArg)) {
						if (Construct->getNumArgs() >= 2) {
							clang::Expr::EvalResult r0, r1;
							if (Construct->getArg(0)->EvaluateAsInt(r0, *Context) &&
								Construct->getArg(1)->EvaluateAsInt(r1, *Context)) {
								tilingMeshRows = r0.Val.getInt().getExtValue();
								tilingMeshCols = r1.Val.getInt().getExtValue();
								llvm::outs() << "[TilingLinalg] Mesh: " << tilingMeshRows << " x " << tilingMeshCols << "\n";
							}
						}
					} else if (const auto *DR = dyn_cast<DeclRefExpr>(meshArg)) {
						// mesh variable already declared — get rows/cols from its initializer
						if (const auto *VD = dyn_cast<VarDecl>(DR->getDecl())) {
							if (VD->hasInit()) {
								if (const auto *Construct = dyn_cast<CXXConstructExpr>(VD->getInit()->IgnoreParenImpCasts())) {
									if (Construct->getNumArgs() >= 2) {
										clang::Expr::EvalResult r0, r1;
										if (Construct->getArg(0)->EvaluateAsInt(r0, *Context) &&
											Construct->getArg(1)->EvaluateAsInt(r1, *Context)) {
											tilingMeshRows = r0.Val.getInt().getExtValue();
											tilingMeshCols = r1.Val.getInt().getExtValue();
											llvm::outs() << "[TilingLinalg] Mesh (from var): " << tilingMeshRows << " x " << tilingMeshCols << "\n";
										}
									}
								}
							}
						}
					}
					// Extract tensor params from the __global__ kernel function signature
					// Args 2+ of __aie_launch correspond to the kernel function parameters
					std::string launchKernelName;
					if (const auto *SL2 = dyn_cast<clang::StringLiteral>(CE->getArg(0)->IgnoreParenImpCasts())) {
						launchKernelName = SL2->getString().str();
					}

					if (!launchKernelName.empty()) {
						auto it = globalKernelFuncs.find(launchKernelName);
						if (it != globalKernelFuncs.end()) {
							const FunctionDecl *kernelFD = it->second;
							unsigned numKernelParams = kernelFD->getNumParams();

							// Semantic validation: check launch arg count vs kernel param count
							unsigned numLaunchArgs = CE->getNumArgs() - 2; // exclude name and mesh
							if (numLaunchArgs != numKernelParams) {
								llvm::errs() << "Error: kernel '" << launchKernelName
											 << "' declares " << numKernelParams << " parameters but launch provides "
											 << numLaunchArgs << " arguments.\n";
								llvm::errs() << "  __global__ void " << launchKernelName << "(...) has "
											 << numKernelParams << " params\n";
								llvm::errs() << "  " << launchKernelName << "<<<mesh>>>(...) provides "
											 << numLaunchArgs << " args\n";
								// Don't abort — continue with available info
							}

							// First pass: collect scalar dimension values from launch args
							// Launch args start at index 2 (0=name, 1=mesh, 2..=kernel params)
							std::vector<int64_t> scalarDimValues;
							for (unsigned i = 0; i < numKernelParams; ++i) {
								const ParmVarDecl *kp = kernelFD->getParamDecl(i);
								clang::QualType ptype = kp->getType();
								if (!ptype->isPointerType()) {
									// Scalar param — try to evaluate from launch arg
									unsigned launchArgIdx = i + 2;
									if (launchArgIdx < CE->getNumArgs()) {
										clang::Expr::EvalResult evalRes;
										if (CE->getArg(launchArgIdx)->EvaluateAsInt(evalRes, *Context)) {
											scalarDimValues.push_back(evalRes.Val.getInt().getExtValue());
										}
									}
								}
							}

							// Determine default shape from scalar dims (e.g. M, N, K -> MxN for each tensor)
							// For GEMM: A[M*K], B[K*N], C[M*N] with scalars [M, N, K]
							// General case: use first two scalars as shape for all tensors
							int64_t defaultDim0 = 16, defaultDim1 = 16;
							if (scalarDimValues.size() >= 2) {
								defaultDim0 = scalarDimValues[0];
								defaultDim1 = scalarDimValues[1];
							} else if (scalarDimValues.size() == 1) {
								defaultDim0 = defaultDim1 = scalarDimValues[0];
							}

							// Second pass: build ParsedTensorInfo for each pointer parameter
							for (unsigned i = 0; i < numKernelParams; ++i) {
								const ParmVarDecl *kp = kernelFD->getParamDecl(i);
								clang::QualType ptype = kp->getType();
								if (ptype->isPointerType()) {
									clang::QualType pointee = ptype->getPointeeType();
									bool isConst = pointee.isConstQualified();

									// Check for window-type parameters: input_window<T>* or output_window<T>*
									std::string pointeeStr = pointee.getUnqualifiedType().getAsString();
									bool isWindowParam = false;
									bool isInputWindow = false;
									int bitWidth = 32; // default

									if (pointeeStr.find("input_window") != std::string::npos) {
										isWindowParam = true;
										isInputWindow = true;
									} else if (pointeeStr.find("output_window") != std::string::npos) {
										isWindowParam = true;
										isInputWindow = false;
									}

									if (isWindowParam) {
										// Extract element bit width from window type name
										// e.g. "input_window_int8" or "input_window<signed char>"
										if (pointeeStr.find("int8") != std::string::npos ||
											pointeeStr.find("signed char") != std::string::npos ||
											pointeeStr.find("char") != std::string::npos)
											bitWidth = 8;
										else if (pointeeStr.find("int16") != std::string::npos ||
												 pointeeStr.find("short") != std::string::npos)
											bitWidth = 16;
										// else default int32
									} else {
										// Plain pointer type (e.g. const int32_t*)
										if (pointee->isSpecificBuiltinType(clang::BuiltinType::Int))
											bitWidth = 32;
										else if (pointee->isSpecificBuiltinType(clang::BuiltinType::Short))
											bitWidth = 16;
										else if (pointee->isSpecificBuiltinType(clang::BuiltinType::SChar) ||
												 pointee->isSpecificBuiltinType(clang::BuiltinType::Char_S) ||
												 pointee->isSpecificBuiltinType(clang::BuiltinType::UChar))
											bitWidth = 8;
										else if (const auto *BT = pointee->getAs<clang::BuiltinType>()) {
											bitWidth = Context->getTypeSize(BT);
										}
									}

									ParsedTensorInfo pti;
									pti.varName = kp->getNameAsString();
									pti.shape = {defaultDim0, defaultDim1};
									pti.elementBitWidth = bitWidth;
									pti.isInput = isWindowParam ? isInputWindow : isConst;

									parsedTensors.push_back(pti);
									llvm::outs() << "[TilingLinalg] Tensor param: " << pti.varName
												 << " [" << pti.shape[0] << "x" << pti.shape[1] << "] i"
												 << pti.elementBitWidth
												 << (pti.isInput ? " (input)" : " (output)") << "\n";
								}
							}
						}
					}
				}
				return true;
			}

			if (Callee && Callee->getNameAsString() =="XAie_LoadElfMem") {
                if (CE->getNumArgs() >= 3) {
                    const Expr *devExpr = CE->getArg(0);
                    const Expr *tileExpr = CE->getArg(1);
                    const Expr *kernelExpr = CE->getArg(2)->IgnoreParenImpCasts();

                    std::string devStr;
                    llvm::raw_string_ostream devOs(devStr);
                    devExpr->printPretty(devOs, nullptr, PrintingPolicy(LangOptions()));
                    devOs.flush();

                    std::string tileStr;
                    llvm::raw_string_ostream tileOs(tileStr);
                    tileExpr->printPretty(tileOs, nullptr, PrintingPolicy(LangOptions()));
                    tileOs.flush();

                    std::string kernelArgStr;
                    llvm::raw_string_ostream kernelArgOs(kernelArgStr);
                    kernelExpr->printPretty(kernelArgOs, nullptr, PrintingPolicy(LangOptions()));
                    kernelArgOs.flush();
                    boost::algorithm::trim(kernelArgStr);

                    if (kernelArgStr.find("_binary_kernel_") != std::string::npos) {
                        return true;
                    }

                    const Expr *kernelNameExpr = kernelExpr;
                    while (const auto *castExpr = dyn_cast<CastExpr>(kernelNameExpr)) {
                        kernelNameExpr = castExpr->getSubExpr()->IgnoreParenImpCasts();
                    }
                    if (const auto *unaryExpr = dyn_cast<UnaryOperator>(kernelNameExpr)) {
                        if (unaryExpr->getOpcode() == UO_AddrOf) {
                            kernelNameExpr = unaryExpr->getSubExpr()->IgnoreParenImpCasts();
                        }
                    }

                    std::string kernelName;
                    if (const auto *declRef = dyn_cast<DeclRefExpr>(kernelNameExpr)) {
                        kernelName = declRef->getDecl()->getNameAsString();
                    } else {
                        return true;
                    }

                    std::string replacement = "XAie_LoadElfMem(" + devStr + ", " + tileStr +
                                              ", (unsigned char *)_binary_kernel_" + kernelName + "_start)";
                    clang::SourceRange callExprRange = CE->getSourceRange();
                    Rewrite->ReplaceText(callExprRange, replacement);
                }
            } else {
					if (Callee) {
						for (auto x:kernel_name_list) {
							// std::cout << "kernel name is (" << x << ")" <<std::endl;
							if (Callee->getNameAsString() == x) {
								llvm::outs()<< "**************Function name is " << Callee->getNameInfo().getName().getAsString() <<"*********8\n";
							
								if (auto FD = CE->getDirectCallee()) {

									// 2) Check if it’s actually a specialization of a function template:
									if (auto  TSI = FD->getTemplateSpecializationInfo()) {
								
										// 3) Grab the FunctionTemplateDecl (the “template name”):
										auto FTD = FD->getPrimaryTemplate();
										llvm::outs() << "Template name: "
													<< FTD->getNameAsString() << "\n";
									
										// 4) Extract the explicit template-argument list:
										ArrayRef<TemplateArgument> Args = 
											TSI->TemplateArguments->asArray();
									
										llvm::outs() << "Template args: <";
										std::vector<std::string> knames;
										for (size_t i = 0; i < Args.size(); ++i) {
											const TemplateArgument &Arg = Args[i];
											llvm::SmallString<16> Buf;
											switch (Arg.getKind()) {
											case TemplateArgument::Integral:
												
												Arg.getAsIntegral().toString(Buf, 10);
												llvm::outs() << Buf;
												//std::string kname(Buf.begin(), Buf.end());
												//kname = Buf.str().str();
												knames.push_back(Buf.str().str());
												break;
											case TemplateArgument::Type:
												llvm::outs() << Arg.getAsType().getAsString();
												break;
											default:
												llvm::outs() << "(other)";
											}
											if (i + 1 < Args.size()) llvm::outs() << ", ";
										}
										llvm::outs() << ">\n\n";
										Aiefrontend->createKernelFunction(knames);
									}
								}
								
							}
						}
					} else {
						auto Call = CE->getCallee();
						if (Call) {
							//llvm::errs() << "Indirect function call or function pointer dereference\n";
							//Call->dump();  // You can inspect the callee expression
						}
					}
            // If Callee is null, it may be an indirect function call or a function pointer.
            // You can handle those cases accordingly.
            //llvm::outs() << "Indirect function call or function pointer\n";
			}
			return true;
    }
/*
		 bool VisitParmVarDecl(ParmVarDecl *PVD) {
        // Handle function parameters
        if (!PVD->hasInit()) {
          // Parameter does not have an initializer
          llvm::outs() << "Parameter without initializer: " << PVD->getNameAsString() << "\n";
        }
        return true;
      }

      bool VisitVarDecl(VarDecl *VD) {
        // Handle local variables
        if (!VD->hasInit()) {
          // Variable does not have an initializer
          llvm::outs() << "Variable without initializer: " << VD->getNameAsString() << "\n";
        }
        return true;
     }
		  bool VisitDecl(Decl *D) {
        // Check for "unknown type name 'windows'" error
				//std::cout << "unknow VisitDecl" <<std::endl;
				//return false;
				std::cout << "Decl is " << D->getDeclKindName() << std::endl;
        if (isa<UnresolvedUsingTypenameDecl>(D)) {
        }

        return true;
      }
			*/

		 void PrintCode() {
    	// Apply the rewrite to the source file
    	//Rewrite.commit(rewriter::Rewriter::Commit);
			//std::string RewrittenCode = Rewrite.getEditBuffer(Rewrite.getSourceMgr().getMainFileID()).getBuffer();
			 std::cout << "---------****---------" << std::endl;
			 ///*
			 const RewriteBuffer *RewriteBuf = Rewrite->getRewriteBufferFor(Rewrite->getSourceMgr().getMainFileID());
			 if (RewriteBuf) {
        //llvm::outs() << "Rewritten Source Code:\n" << RewriteBuf << "\n";
			//*/
			 //std::ofstream fd("./new_t.c");
				 RewriteBuf->write(llvm::outs());
		 }
			 /*
			 auto& sc = Rewrite.getSourceMgr();
			 auto mid = sc.getMainFileID();
			 llvm::StringRef sourceCode = sc.getBufferData(mid);
			 llvm::outs() << "Original Source Code:\n" << sourceCode << "\n";
			 */
			 std::cout << "------------------" << std::endl;
			//llvm::outs() << "Rewritten Source Code:\n" << RewrittenCode << "\n";
  	}


private:
		AieFrontEnd* Aiefrontend;
    ASTContext *Context;
		Rewriter *Rewrite;
};

class MyASTConsumer : public ASTConsumer {
public:
    //explicit MyASTConsumer(ASTContext *Context)
      //  : Visitor(Context) {}

    explicit MyASTConsumer(Rewriter* TheRewriter, ASTContext *Context, AieFrontEnd* Aiefrontend)
        : Visitor(TheRewriter, Context, Aiefrontend) {}

    void HandleTranslationUnit(ASTContext &Context) override {
        Visitor.TraverseDecl(Context.getTranslationUnitDecl());
		// std::cout << __FUNCTION__ << " get called " << std::endl;
    }

private:
    GlobalFunctionVisitor Visitor;
};

class AieDebugLevelPragmaHandler : public clang::PragmaHandler {
  public:
    AieDebugLevelPragmaHandler() : PragmaHandler("aie_debug_level") {}

    void HandlePragma(clang::Preprocessor &PP, clang::PragmaIntroducer Introducer, clang::Token &FirstToken) override {
        clang::Token Tok;
        PP.Lex(Tok);
        if (Tok.is(clang::tok::numeric_constant)) {
            llvm::SmallString<8> IntegerBuffer;
            bool Invalid = false;
            llvm::StringRef Spelling = PP.getSpelling(Tok, IntegerBuffer, &Invalid);
            if (!Invalid) {
                int level = 0;
                if (!Spelling.getAsInteger(10, level)) {
                    parsedDebugLevel = level;
                    llvm::outs() << "[aiehlc] Detected #pragma aie_debug_level " << parsedDebugLevel << "\n";
                }
            }
        }
        // Consume remaining tokens on the pragma line
        PP.DiscardUntilEndOfDirective();
    }
};

class MyFrontendAction : public ASTFrontendAction {
public:
		MyFrontendAction() {
			FileMgr = std::make_unique<clang::FileManager>(clang::FileSystemOptions());
			aiefrontend.set_llvm_aie(use_llvm_aie);
		}
		void ReplaceGlobalKeyAndAddInclude(clang::SourceManager &SourceMgr) {
			std::unordered_map<std::string, std::string> replace_map={{"__global__","__attribute__((annotate(\"__global__\")))"},
																	  {"__kernel__","__attribute__((annotate(\"__kernel__\")))"}};
			//auto SourceCodeString = GetKeyReplaceAndAddInclude(SourceMgr, "__global__",
			//		"__attribute__((annotate(\"__global__\")))");
			auto SourceCodeString = GetKeyReplaceAndAddInclude(SourceMgr, replace_map);
			llvm::StringRef ModifiedCode = SourceCodeString;

            // Save a physical copy of the preprocessed file for debugging/inspection
            std::string newfilePath = std::string(AOUT) + "newfile.cpp";
            std::ofstream newfileOut(newfilePath, std::ios::out | std::ios::trunc);
            if (newfileOut.is_open()) {
                newfileOut << SourceCodeString;
                newfileOut.close();
                llvm::outs() << "Saved preprocessed file to: " << newfilePath << "\n";
            }

            std::unique_ptr<llvm::MemoryBuffer> ModifiedBuffer =
					 llvm::MemoryBuffer::getMemBufferCopy(ModifiedCode,"NewCode");
			// std::cout << "new ----------" << code << std::endl;
			// auto src = code.c_str();
			// std::cout << "new ---src-------" << src << std::endl;

			//const char* src = "__attribute__((annotate(\"__global__\"))) int func () {} \n int main() {}";
			//std::unique_ptr<llvm::MemoryBuffer> Buf = llvm::MemoryBuffer::getMemBuffer(src);
			const FileEntryRef SourceFile = FileMgr->getVirtualFileRef("newfile.cpp", ModifiedBuffer->getBufferSize(), 0);
			//FileEntryRef fileEntryRef = SourceMgr.translateFile(SourceFile);

			SourceMgr.overrideFileContents(SourceFile, std::move(ModifiedBuffer));
			FileID MainFileID = SourceMgr.getOrCreateFileID(SourceFile, SrcMgr::C_User);
			SourceMgr.setMainFileID(MainFileID);
		}
	 /* do pre-processing change the __global__ into annotation
	  */
	  bool BeginSourceFileAction(CompilerInstance &CI) override {
			//auto& ppopts = CI.getPreprocessorOpts();
			// std::cout <<"File is " << "Filename.str()" << std::endl;
 			clang::SourceManager &SourceMgr = CI.getSourceManager();

			ReplaceGlobalKeyAndAddInclude(SourceMgr);

            clang::Preprocessor &PP = CI.getPreprocessor();
            PP.AddPragmaHandler(new AieDebugLevelPragmaHandler());

            return true;
		}

		std::string GetKeyReplaceAndAddInclude(clang::SourceManager &SourceMgr, std::unordered_map<std::string,std::string>& funcMap) {
			std::string ret;
			// Get the main file entry
			const auto FileEntryRef = SourceMgr.getFileEntryRefForID(SourceMgr.getMainFileID());

			if (FileEntryRef) {
				// Get the file name
				llvm::StringRef FileName = FileEntryRef->getName();

				// Print or use the file name as needed
				// llvm::outs() << "Processing file: " << FileName << "\n";
				clang::FileID MainFileID = SourceMgr.getMainFileID();

				// Get the source code buffer for the main file
				//const llvm::MemoryBuffer *MainFileBuffer = SourceMgr.getBuffer(MainFileID);
				const auto MainFileBufferOp = SourceMgr.getBufferOrNone(MainFileID);
				const llvm::MemoryBufferRef *MainFileBuffer = &MainFileBufferOp.value();
				// Get the source code as a StringRef
				llvm::StringRef SourceCode = MainFileBuffer->getBuffer();
				// std::cout << SourceCode.str() << std::endl;
				std::unique_ptr<llvm::MemoryBuffer> Buffer = llvm::MemoryBuffer::getMemBuffer(SourceCode, "", false);

				llvm::SourceMgr SM;
				SM.AddNewSourceBuffer(std::move(Buffer), llvm::SMLoc());
				//replace keyword with annotate
				//std::string KeywordToReplace = sOld;//"__global__";
				//std::string Replacement = sNew;//"__attribute__((annotate(\"__global__\")))";

				//llvm::StringRef UpdatedSource;
				std::string SourceCodeString = SourceCode.str();
				size_t KeywordPos = 0;
				for (auto x:funcMap ) {
					std::string KeywordToReplace = x.first;//"__global__";
					std::string Replacement = x.second;//"__attribute__((annotate(\"__global__\")))";
					size_t KeywordPos = 0;
					while ((KeywordPos =  SourceCodeString.find(KeywordToReplace, KeywordPos)) != std::string::npos) {
						int pos = KeywordPos;
						bool bgstr = false;
						// check whether the __global_ is inside a '"', actually just check the front '"'
						while(--pos >=0) {
							if (SourceCodeString[pos] == ' ') continue;
							if (SourceCodeString[pos] == '"' || SourceCodeString[pos] == '/' || SourceCodeString[pos] == '*') {
								bgstr = true;
							}
							break;
						}
						if (!bgstr) {
							//process the kernel logic
							auto curkeywordpos = KeywordPos;
							if (KeywordToReplace == "__kernel__") {
								auto bracepos = SourceCodeString.find("(", curkeywordpos);
								auto curpos = bracepos;
								while(--curpos >=0){
									if (SourceCodeString[curpos] == ' ') break;
								}
								curpos++;
							
								auto str = SourceCodeString.substr(curpos, bracepos - curpos);
								while(str[str.size() -1] == ' ') {
									str = str.substr(0, str.size() - 1);
								}
								kernel_name_list.push_back(str);
							}
							//replace
							SourceCodeString.replace(KeywordPos, KeywordToReplace.size(), Replacement);
							KeywordPos += Replacement.size();

                            // For __global__ functions, wrap body with #ifdef KERNEL_COMPILE
                            if (KeywordToReplace == "__global__") {
                                // Find the opening brace of the function body
                                auto openBracePos = SourceCodeString.find("{", KeywordPos);
                                if (openBracePos != std::string::npos) {
                                    // Insert #ifdef KERNEL_COMPILE after opening brace
                                    std::string ifdefGuard = "\n#ifdef KERNEL_COMPILE\n";
                                    SourceCodeString.insert(openBracePos + 1, ifdefGuard);

                                    // Find matching closing brace
                                    int braceCount = 1;
                                    size_t searchPos = openBracePos + 1 + ifdefGuard.size();
                                    while (braceCount > 0 && searchPos < SourceCodeString.size()) {
                                        if (SourceCodeString[searchPos] == '{')
                                            braceCount++;
                                        else if (SourceCodeString[searchPos] == '}')
                                            braceCount--;
                                        if (braceCount > 0)
                                            searchPos++;
                                    }
                                    // Insert #endif before closing brace
                                    if (braceCount == 0) {
                                        std::string endifGuard = "\n#endif\n";
                                        SourceCodeString.insert(searchPos, endifGuard);
                                    }
                                }
                            }

                        } else {
							KeywordPos += KeywordToReplace.size();
						}
					}
				}
				// Transform <<<mesh>>> kernel launch syntax (CUDA-style)
				// Pattern: funcname<<<varname>>>(args) -> __aie_launch("funcname", varname, args)
				{
					size_t launchPos = 0;
					while ((launchPos = SourceCodeString.find("<<<", launchPos)) != std::string::npos) {
						// Find the function name before <<<
						size_t funcEnd = launchPos;
						while (funcEnd > 0 && (std::isalnum(SourceCodeString[funcEnd-1]) || SourceCodeString[funcEnd-1] == '_'))
							funcEnd--;
						std::string funcName = SourceCodeString.substr(funcEnd, launchPos - funcEnd);

						// Find mesh variable name between <<< and >>>
						size_t meshStart = launchPos + 3;
						size_t meshEnd = SourceCodeString.find(">>>", meshStart);
						if (meshEnd == std::string::npos) break;
						std::string meshVar = SourceCodeString.substr(meshStart, meshEnd - meshStart);
						// trim whitespace
						meshVar.erase(0, meshVar.find_first_not_of(" \t"));
						meshVar.erase(meshVar.find_last_not_of(" \t") + 1);

						// Find args between ( and )
						size_t argsOpenParen = SourceCodeString.find("(", meshEnd + 3);
						if (argsOpenParen == std::string::npos) break;
						int depth = 1;
						size_t argsEnd = argsOpenParen + 1;
						while (depth > 0 && argsEnd < SourceCodeString.size()) {
							if (SourceCodeString[argsEnd] == '(') depth++;
							if (SourceCodeString[argsEnd] == ')') depth--;
							if (depth > 0) argsEnd++;
						}
						std::string args = SourceCodeString.substr(argsOpenParen + 1, argsEnd - argsOpenParen - 1);

						// Build replacement: __aie_launch("funcName", meshVar, args)
						std::string replacement = "__aie_launch(\"" + funcName + "\", " + meshVar + ", " + args + ")";

						// Replace from funcEnd to argsEnd+1 (include closing paren)
						SourceCodeString.replace(funcEnd, argsEnd + 1 - funcEnd, replacement);
						launchPos = funcEnd + replacement.size();

						// Track that we're in tiling mode
						isTilingLinalgMode = true;
					}
				}

                // ret = "#include <stdio.h>\n";
                // ret += "#include \"adf.h\"\n";

                // Add stub declarations for AIE-specific types that clang can't find
                // (because __AIENGINE__ isn't defined, so adf.h uses different code paths)
                // Function body is wrapped with #ifdef KERNEL_COMPILE so only type stubs needed
                ret +=
                    "// Stub type declarations for Clang parsing (function body skipped via #ifdef KERNEL_COMPILE)\n";
                ret += "#ifndef AIEHLC_STUBS_DEFINED\n";
                ret += "#define AIEHLC_STUBS_DEFINED\n";
                ret += "template<typename T> struct input_window {};\n";
                ret += "template<typename T> struct output_window {};\n";
                ret += "typedef int int32;\n";
                ret += "typedef input_window<int32> input_window_int32;\n";
                ret += "typedef output_window<int32> output_window_int32;\n";
                ret += "typedef signed char int8;\n";
                ret += "typedef input_window<int8> input_window_int8;\n";
                ret += "typedef output_window<int8> output_window_int8;\n";
                ret += "typedef short int16;\n";
                ret += "typedef input_window<int16> input_window_int16;\n";
                ret += "typedef output_window<int16> output_window_int16;\n";
                // Kernel intrinsic stubs (body is #ifdef KERNEL_COMPILE guarded)
                ret += "typedef unsigned char uint8_t;\n";
                ret += "typedef unsigned long uintptr_t;\n";
                ret += "typedef int int8_t __attribute__((mode(QI)));\n";
                ret += "typedef int int32_t __attribute__((mode(SI)));\n";
                ret += "typedef int v4int8 __attribute__((vector_size(4)));\n";
                ret += "typedef int v4int32 __attribute__((vector_size(16)));\n";
                ret += "inline unsigned get_coreid() { return 0; }\n";
                ret += "inline void klog(const char*, int) {}\n";
                ret += "template<typename T> inline void* acquire_input_window(T*) { return (void*)0; }\n";
                ret += "template<typename T> inline void* acquire_output_window(T*) { return (void*)0; }\n";
                ret += "template<typename T> inline void release_input_window(T*) {}\n";
                ret += "template<typename T> inline void release_output_window(T*) {}\n";
                ret += "#define BUF_SZ 16\n";
                ret += "#endif\n\n";

                // CUDA-style AIE API stubs for tiling mode
                if (isTilingLinalgMode) {
                    ret += "// CUDA-style AIE API stubs for Clang parsing\n";
                    ret += "#ifndef AIEHLC_TILING_STUBS_DEFINED\n";
                    ret += "#define AIEHLC_TILING_STUBS_DEFINED\n";
                    ret += "struct aieDim {\n";
                    ret += "    int rows, cols;\n";
                    ret += "    aieDim(int r, int c) : rows(r), cols(c) {}\n";
                    ret += "};\n";
                    ret += "inline void aieSetDevice(int) {}\n";
                    ret += "inline void aieDeviceSynchronize() {}\n";
                    // Stub extern + __aie_launch for Clang AST parsing only.
                    // parsedTensors is empty at this point (pre-AST-visit), so we
                    // emit a no-op template.  The correct forwarding overload is
                    // generated later by TilingLinalgPipeline::runPipeline when
                    // appending user source to host.cc.
                    ret += "extern void host_canonicalized(...);\n";
                    ret += "template<typename... Args>\n";
                    ret += "inline void __aie_launch(const char* kernel, aieDim mesh, Args... args) {\n";
                    ret += "    (void)kernel; (void)mesh; (void)sizeof...(args);\n";
                    ret += "}\n";
                    ret += "#endif\n\n";
                }

                if (!kernel_name_list.empty()) {
                    ret += "#include \"xaiengine.h\"\n";
                    ret += "#ifndef AIEHLC_KERNEL_LAUNCH_HELPERS_DEFINED\n";
                    ret += "#define AIEHLC_KERNEL_LAUNCH_HELPERS_DEFINED\n";
                    ret += "static XAie_DevInst *__aiehlc_global_dev_inst = nullptr;\n";
                    ret += "#define AIEHLC_MAX_LAUNCHED_TILES 1024\n";
                    ret += "static XAie_LocType __aiehlc_launched_tiles[AIEHLC_MAX_LAUNCHED_TILES];\n";
                    ret += "static int __aiehlc_launched_tile_count = 0;\n";
                    ret += "inline void __use_device_instance(XAie_DevInst *DevInst) {\n";
                    ret += "    __aiehlc_global_dev_inst = DevInst;\n";
                    ret += "}\n";
                    ret += "inline void __sync_kernels() {\n";
                    ret += "    if (__aiehlc_global_dev_inst == nullptr) {\n";
                    ret += "        return;\n";
                    ret += "    }\n";
                    ret += "    for (int i = 0; i < __aiehlc_launched_tile_count; ++i) {\n";
                    ret += "        while (XAie_CoreWaitForDone(__aiehlc_global_dev_inst, __aiehlc_launched_tiles[i], "
                           "0) != XAIE_OK) {}\n";
                    ret += "    }\n";
                    ret += "    __aiehlc_launched_tile_count = 0;\n";
                    ret += "}\n";
                    ret += "#endif\n";
                }

                for (auto x:kernel_name_list) {
                    ret += "extern unsigned char _binary_kernel_" + x + "_start[];\n" +
                           "template <int Col, int Row, typename... Args>\n"
                           "inline void " +
                           x +
                           "(Args&&... args) {\n"
                           "    (void)sizeof...(args); \n"
                           "    XAie_DevInst *DevInst = __aiehlc_global_dev_inst;\n"
                           "    if (DevInst == nullptr) {\n"
                           "        return;\n"
                           "    }\n"
                           "    XAie_CoreReset(DevInst, XAie_TileLoc(Col,Row));\n"
                           "    XAie_CoreUnreset(DevInst, XAie_TileLoc(Col,Row));\n"
                           "    XAie_LoadElfMem(DevInst, XAie_TileLoc(Col,Row), (unsigned char *)_binary_kernel_" +
                           x +
                           "_start);\n"
                           "    XAie_CoreEnable(DevInst, XAie_TileLoc(Col,Row));\n"
                           "    if (__aiehlc_launched_tile_count < AIEHLC_MAX_LAUNCHED_TILES) {\n"
                           "        __aiehlc_launched_tiles[__aiehlc_launched_tile_count++] = XAie_TileLoc(Col,Row);\n"
                           "    } else {\n"
                           "        while (XAie_CoreWaitForDone(DevInst, XAie_TileLoc(Col,Row), 0) != XAIE_OK) {}\n"
                           "    }\n"
                           "    return;\n"
                           "};\n";
                }
                ret += SourceCodeString;
				// std::cout << ret << std::endl;
				/*
					 llvm::StringRef ModifiedCode = SourceCodeString;
					 std::unique_ptr<llvm::MemoryBuffer> ModifiedBuffer =
					 llvm::MemoryBuffer::getMemBufferCopy(ModifiedCode," Filename");

					 SourceMgr.overrideFileContents(FileEntry, std::move(ModifiedBuffer));

				// Get the modified file name
				llvm::StringRef ModifiedFileName = SourceMgr.getFileEntryForID(SourceMgr.getMainFileID())->getName();

				// Print modified file name
				llvm::outs() << "Modified file name: " << ModifiedFileName  << ModifiedCode<< "\n";
				*/
			}
			return ret;
		}

		void EndSourceFileAction() override {
			//  std::cout << "---------EndSourceFileAction---------" << std::endl;
			 const RewriteBuffer *RewriteBuf = TheRewriter.getRewriteBufferFor(TheRewriter.getSourceMgr().getMainFileID());
			 if (RewriteBuf) {
				 //RewriteBuf->write(llvm::outs());
        //llvm::outs() << "Rewritten Source Code:\n" << RewriteBuf << "\n";
	  		} else {
					llvm::errs() << "RewriteBuf is null\n";
				}

			if (isTilingLinalgMode) {
				// ---- NEW PATH: tilinglinalg pipeline ----
				llvm::outs() << "[TilingLinalg] Running multi-tile pipeline (mesh="
							 << tilingMeshRows << "x" << tilingMeshCols << ")\n";

                // Capture user's rewritten source for merging with pipeline output.
                // The RewriteBuf contains the entire user source with __global__ body
                // removed and <<<mesh>>> syntax replaced by __aie_launch() calls.
                std::string userRewrittenSource;
                if (RewriteBuf) {
                    llvm::raw_string_ostream rso(userRewrittenSource);
                    RewriteBuf->write(rso);
                    rso.flush();
                }

                mlir::MLIRContext ctx;
				TilingLinalgPipeline::registerDialects(ctx);

				// Build tensor params — use defaults matching unitest if not parsed
				std::vector<TensorParam> tensors;
				if (parsedTensors.empty()) {
					// Default: single input tensor 16x16 i8 (same as unitest)
					tensors.push_back({{16, 16}, 8, true});
				} else {
					for (auto &pt : parsedTensors) {
						tensors.push_back({pt.shape, pt.elementBitWidth, pt.isInput});
					}
				}

				// Use default mesh if not parsed
				int rows = tilingMeshRows > 0 ? tilingMeshRows : 2;
				int cols = tilingMeshCols > 0 ? tilingMeshCols : 2;

				// Build routing IR
				auto module = TilingLinalgPipeline::buildRoutingIR(ctx, rows, cols, tensors);

				// Run pipeline -> writes host.cc, kernel.cc, routing.cc, BCF, PRX
				std::string outputDir = std::string(AOUT) + "worklocal/";
                if (TilingLinalgPipeline::runPipeline(ctx, module, outputDir, userKernelBody, userKernelFuncName,
                                                      parsedDebugLevel, userRewrittenSource)) {
                    llvm::outs() << "[TilingLinalg] Pipeline completed. Output in: " << outputDir << "\n";
                } else {
                    llvm::errs() << "[TilingLinalg] Pipeline FAILED.\n";
                }
            } else {
				// ---- EXISTING PATH: single-tile ----
				std::error_code error_code;
				llvm::outs() << "Exporting File: " << std::string(AOUT)+"./host.cc" << "\n";
				llvm::raw_fd_ostream outFile(std::string(AOUT)+"./host.cc", error_code, llvm::sys::fs::OF_None);
				if (error_code) {
					llvm::errs() << "Error opening file: " << error_code.message() << "\n";
					return ;  // Exit early if there's an error
				}
                // Emit strong g_runtime_debug_level override if user set #pragma aie_debug_level
                if (parsedDebugLevel >= 0) {
                    outFile << "// Override runtime debug level (from #pragma aie_debug_level)\n";
                    outFile << "int g_runtime_debug_level = " << parsedDebugLevel << ";\n\n";
                }
                //fd.write(RewriteBuf->data(), RewriteBuf->size());
				RewriteBuf->write(outFile);
				/*
				auto& sc = Rewrite.getSourceMgr();
				auto mid = sc.getMainFileID();
				llvm::StringRef sourceCode = sc.getBufferData(mid);
				llvm::outs() << "Original Source Code:\n" << sourceCode << "\n";
				*/
				const std::string fname = "aie.mlir";
				auto mlirstr = aiefrontend.dumpir();
				std::ofstream ofs(fname);
				if (ofs.is_open()) {
						ofs << mlirstr;
						ofs.close();
				}
				aiefrontend.RunPass(fname);
			}
			//  std::cout << "----------------end-----------------" << std::endl;
  	}
    std::unique_ptr<ASTConsumer> CreateASTConsumer(CompilerInstance &CI,
                                                   StringRef file) override {

				//disable the error information
			    // auto& dg = CI.getDiagnostics();
				// auto& Context = CI.getASTContext();
				// unsigned IgnoredErrorID = Context.getDiagnostics().getCustomDiagID(DiagnosticsEngine::Error,
				// 		"This error is ignored");
				// dg.setClient(new IgnoringDiagConsumer(), /*ShouldOwn=*/true);
				// CI.createDiagnostics(new IgnoringDiagConsumer(), /*ShouldOwnClient=*/false);

				TheRewriter.setSourceMgr(CI.getSourceManager(), CI.getLangOpts());			
        return std::make_unique<MyASTConsumer>(&TheRewriter,&CI.getASTContext(), &aiefrontend);
    }
private:
		std::string code;
		AieFrontEnd aiefrontend;
		Rewriter TheRewriter;
		std::unique_ptr<clang::FileManager> FileMgr;
		//FileManager FileMgr;
};
extern void dumpmlir();

void trycreatefolder(std::string dirPath) {
	///*
	std::string command = "mkdir -p " + dirPath; 
	int result = system(command.c_str());           // Run the command

	if (result == 0) {
		// std::cout << "Directory created." << std::endl;
	} else {
		std::cerr << "Failed to create directory." << std::endl;
	}
}

static llvm::cl::opt<std::string> IncludePath(
			"I", llvm::cl::desc("Specify include path (-I)"), llvm::cl::value_desc("path"));

llvm::cl::OptionCategory MyToolCategory("aiehlc options");
static llvm::cl::opt<bool> LLVMAie(
			"use-llvm-aie", llvm::cl::desc("Enable use of LLVM AIE"), llvm::cl::init(false), llvm::cl::cat(MyToolCategory));

int main(int argc, const char **argv) {

	trycreatefolder(AOUT);
	// std::cout << "main--" << IncludePath.getValue() << std::endl;
	// /*
    //CommonOptionsParser exp(argc, argv, MyToolCategory);
    ///*
	if (argc > 2) {
		if (strcmp(argv[1], "pass") == 0) {
			const char * mlirf = argv[2];
			AieFrontEnd af;
			std::string smlir(mlirf);
			af.Parser(smlir);
			return 0;
		}
	}
    auto ExpectedParser = CommonOptionsParser::create(argc, argv, MyToolCategory, llvm::cl::OneOrMore);
    if (!ExpectedParser) {
		llvm::errs() << "Error: " << llvm::toString(ExpectedParser.takeError()) << "\n";
        // Handle error
        return 1;
    }
    CommonOptionsParser &OptionsParser = ExpectedParser.get();
	use_llvm_aie = LLVMAie;
    //*/
    /*
    auto& OriginalCompilations = OptionsParser.getCompilations();
    std::vector<CompileCommand> newCommands;
    for (const auto& SourceFile : OptionsParser.getSourcePathList()) {
        auto CompileCommandsForFile = OriginalCompilations.getCompileCommands(SourceFile);
	for (auto &Command : CompileCommandsForFile) {
            Command.CommandLine.push_back("-x");
            Command.CommandLine.push_back("c++");
	    newCommands.push_back(Command);
	}

    }
    /*
    FixedCompilationDatabase ( "/scratch/staff/huaj/mlir/acompiler/build/../src/llvm/", newCommands);
    auto NewCompilations = std::make_shared<FixedCompilationDatabase>(newCommands);
		        //    "/scratch/staff/huaj/mlir/acompiler/build/../src/llvm/", newCommands);
    //ClangTool Tool(*NewCompilations,
    //               OptionsParser.getSourcePathList());
    
    std::string Directory = "/scratch/staff/huaj/mlir/acompiler/build/../src/llvm/";
    const char* CompileArgs[]= {"-std=c++11", " -x", "c++"};
    int n = 3;
    auto Compilations = FixedCompilationDatabase::loadFromCommandLine(n, CompileArgs, Directory);
    */
		//dumpmlir();
    ClangTool Tool(OptionsParser.getCompilations(),
                   OptionsParser.getSourcePathList());

	if (!IncludePath.empty()) {
		// Add the -I include path argument before the source file arguments
		Tool.appendArgumentsAdjuster(
				getInsertArgumentAdjuster(("-I" + IncludePath).c_str(), ArgumentInsertPosition::BEGIN));
	}
    return Tool.run(newFrontendActionFactory<MyFrontendAction>().get());
}
